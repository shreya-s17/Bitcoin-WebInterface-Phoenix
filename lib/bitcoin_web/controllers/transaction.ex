defmodule TRANSACTION do
    require GENSERVERS
  
    alias Bitcoin.Repo
    alias Bitcoin.Transactions
    #----------- Function to start transactions in the chain ------------ #
    def transactionChain(numTxns, transferAmt) do
      hashList = :ets.lookup(:table,"PublicKeys")
      |> Enum.map(fn {_, x}->
        x
      end)
      if(numTxns == 0) do
        :ets.insert(:table, {"Error", "Got 0 transactions to perform"})
      else
        if(transferAmt <0) do
          :ets.insert(:table, {"Error", "Transfer amount is invalid"})
        else
          recursivePropagation(numTxns, hashList, transferAmt)
        end
      end
    end
  
    # ------- Recursive function for spawning tasks of transactions ------ #
    def recursivePropagation(numTxns, hashList, transferAmt) do
      if(numTxns != 0) do
        WALLETS.updateUnspentAmount()
       generateTxn(hashList, transferAmt,0)
       Process.sleep(100)
       spawn(fn ->recursivePropagation(numTxns-1, hashList,transferAmt ) end)
      end
    end
  
    # ---------- Creates input/output format for transaction ------------- #
    def generateTxn(hashList, transferAmt,count) do
      if(count >10) do
        IO.puts "Most of the transactions do not have transfer amount"
      else
        address1 = Enum.random(hashList)
        [_,_,unspentAmt] = GenServer.call(String.to_atom("h_"<>address1),{:getState})
        if(unspentAmt == 0) do generateTxn(hashList, transferAmt,count+1) end
        out = WALLETS.getUnspentTxns(address1,transferAmt)
        if(out != NULL) do
          inputtxIds = Enum.map(out, fn [a,x,y,_]-> [a,x,y] end)
          [_, _, _, amount] = Enum.at(out, 0)
          {outputs,fee} = WALLETS.getOutputs(amount, transferAmt, hashList, address1)
          rawTransaction(inputtxIds, outputs, address1, fee)
        end
      end
    end
  
    # ---------------- Structure for storing txn attributes ------------ #
    defstruct [
      :hash,
      :inputs,
      :public_key,
      :signature,
      :outputs
    ]
  
    # ------------------ Creation of Coinbase transaction ------------------ #
    def coinBase(output, amount) do
      tx = %TRANSACTION{
        outputs: [[output, amount]],
        inputs: [["0", 0]]
      }
      transRef = Enum.reduce(tx.inputs ++ tx.outputs, "", fn [str, int], acc ->
        acc <> str <> Float.to_string(int/1)
      end)
      |> KEYGENERATION.hash(:sha256)
      |> KEYGENERATION.hash(:sha256)
      |> Base.encode16()
      map = %{sig: "", inputTxIds: [], inputs: {"0",0}, outputs: tx.outputs}
      {"",transRef, 0, map}
    end
  
    # ----------- Transaction format for generation Tx IDs -------------------- #
    def rawTransaction(inputs, outputs, currNode, transFee) do
      tempInputs = Enum.map(inputs, fn [_,x,y]-> [x,y] end)
      transRef = Enum.reduce(tempInputs ++ outputs, "", fn [str, int], acc ->
        acc <> str <> Float.to_string(int/1)  end)
      |> KEYGENERATION.hash(:sha256)
      |> KEYGENERATION.hash(:sha256)
      |> Base.encode16()
  
      [privateKey, publicKey, _] = GenServer.call(String.to_atom("h_" <> currNode),{:getState})
      signedHash = sign(publicKey, privateKey) |> Base.encode16
      scriptSignature = Integer.to_string(String.length(signedHash) + 1)
      <> signedHash
      <> "01"
      <> publicKey
      inputs1 = Enum.map(inputs, fn [_,a,_]-> a end)
      #Io.inspect inputs
      amt = Enum.reduce(outputs,0, fn [_,a], acc->acc+ a end)
      map = %{sig: scriptSignature, inputTxIds: inputs1,
          inputs: {currNode, amt+transFee}, outputs: outputs}
      map1= %{tid: transRef, amount: Enum.at(Enum.at(outputs,0),1)}
      struct(Transactions, map1) |> Repo.insert
      #IO.inspect Repo.all(Transactions)
      :ets.insert(:table, {"pendingTxns", transRef, transFee, map})
      #IO.inspect(:ets.lookup(:table,{:pendingTxns}))
    end
  
    # ----------------- Function for signing using private key ------------------- #
    def sign(val, key) do
      signedHash = :crypto.sign(:ecdsa, :sha256, val,
        [Base.decode16!(key), :secp256k1])
      |> KEYGENERATION.hash(:sha256)
      signedHash
    end
  
    def createInitialTransactions(transferAmt, transNo, nbits) do
      TRANSACTION.transactionChain(transNo, transferAmt)
      Process.sleep(200)
      TASKFINDER.run(Enum.count(:ets.lookup(:table,"Blocks")), nbits, 0)
    end
  
    def testSetup(numNodes) do
      nbits = BLOCKCHAIN.calculateNBits()
      BLOCKCHAIN.initializeGenesisBlock(numNodes, nbits)
    end
  end
  