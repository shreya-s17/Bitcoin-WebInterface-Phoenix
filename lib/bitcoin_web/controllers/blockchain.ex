defmodule BLOCKCHAIN do

    alias Bitcoin.Repo
    alias Bitcoin.Blocks

    @difficulty_target "00805F511E5157EB90B7754ACC85055B19EA74B43BD0F1D7A066946F973F87E8"
    @miningValue 25
    def calculateMerkleRoot(list,i) do
        count = Enum.count(list)
        #IO.puts(" count #{inspect list} #{inspect count}")
        if(count == 1) do
            Enum.at(list,0)
        else
            first = Enum.at(list,i)
            list = List.delete_at(list,i)
            {second,list} =if(i+1>=count) do
                        {first,list}
                    else
                        s=Enum.at(list,i)
                        list = List.delete_at(list,i)
                        {s,list}
                    end
            #IO.puts("list #{inspect first} #{inspect second} #{inspect list} #{inspect i} #{inspect Enum.count(list)}")
            list = if(Enum.count(list) == 0) do
                [:crypto.hash(:sha256,:crypto.hash(:sha256,first<>second)) |> Base.encode16]
            else
                List.insert_at(list,i,:crypto.hash(:sha256,:crypto.hash(:sha256,first<>second)) |> Base.encode16)
            end

            #IO.inspect list
            if(i+1>=Enum.count(list)) do
                #IO.inspect list
                calculateMerkleRoot(list,0)
            else
                calculateMerkleRoot(list,i+1)
            end
        end
    end

    def getLatestBlock() do
        list=:ets.lookup(:table,"Blocks")
        {_,_,[hash,_,_,_]} = Enum.at(list,-1)
        hash
    end

    def find6digits(number,i) do
        if(String.at(number,i)=="0") do
            find6digits(number,i+1)
        else
            i
        end
    end

    def calculateNBits() do
        number = @difficulty_target
        digit = find6digits(number,0)
        length = String.length(number)
        result = if(digit==0 && String.slice(number,0..1)>"7F") do
                    Integer.to_string(div(length+2,2),16) <> "00" <> String.slice(number,0..3)
                else
                    digit = if(rem(digit,2) != 0) do
                                digit-1
                            else
                                digit
                            end
                    Integer.to_string(div(length-digit,2),16) <> String.slice(number,digit..digit+5)
                end
        result
    end

    def createCoinBase(transactionFees) do
      keys = :ets.lookup(:table,"PublicKeys")
      list = Enum.map(keys, fn {_,x}->
                TRANSACTION.coinBase(x, transactionFees)
              end)
      list
    end

    def createBlockHeader(miner, transactionList, transactionFees, minerFee, previousBlock,nbits) do
        #change here nultiple coinbase trans for genesis block
        transList = if(miner == NULL) do
                        createCoinBase(transactionFees)
                    else
                        [TRANSACTION.coinBase(String.slice(miner,2..-1),transactionFees+minerFee)| transactionList]
                    end
        count = Enum.count(transList)
        newList = Enum.map(transList, fn {_,x,_,_} -> x end)
        newTransList = Enum.map(transList, fn x-> Tuple.delete_at(x,0) end)
        merkleRoot = calculateMerkleRoot(newList,0)
        version =<<1::32>>
        time =  <<System.system_time(:second)::32>>
        {hash,nonce} = calculateNonce(merkleRoot,version,previousBlock,time,nbits,0)
        [hash, %{version: version, previousBlockHash: previousBlock, merkleRoot: merkleRoot, time: time, nBits: nbits, nonce: nonce},
         count, newTransList]
    end

    def calculateNonce(merkleRoot,version,previousBlock,time,nbits,nonce) do
        hashBlock = :crypto.hash(:sha256,version <> previousBlock <> merkleRoot <> time <> nbits <> <<nonce::32>>) |> Base.encode16
        if(String.slice(hashBlock,0..1) != "00" || String.at(hashBlock,2) =="0" || hashBlock > @difficulty_target) do
            calculateNonce(merkleRoot,version,previousBlock,time,nbits,nonce+1)
        else
            {hashBlock,nonce}
        end
    end

    def createGenesisBlock(nbits) do
        block = createBlockHeader(NULL, [], @miningValue, 0, "0000000000000000000000000000000000000000000000000000000000000000",nbits)
        Enum.each(Enum.at(block,3), fn {txid, txfee, map} -> :ets.insert(:table, {"unspentTxns", txid, txfee, map}) end)
        WALLETS.updateUnspentAmount()
        map=%{blockNo: 1, blockId: Enum.at(block,0), reward: 0, transCount: Enum.count(Enum.at(block,3))}
        struct(Blocks, map) |> Repo.insert
        block
    end

    def validateHash(hash, map) do
        hashBlock = :crypto.hash(:sha256,Map.get(map,:version) <> Map.get(map,:previousBlockHash) <> Map.get(map,:merkleRoot)
        <> Map.get(map,:time) <> Map.get(map,:nBits) <> <<Map.get(map,:nonce)::32>>) |> Base.encode16
        if(hash == hashBlock && String.slice(hashBlock,0..1) == "00"
         && String.at(hashBlock,2) !="0" && hashBlock <= @difficulty_target) do
            true
        else
            false
        end
    end

    def validateAllHash(list) do
        Enum.all?(list, fn {_,_,block} ->
        [hash, map, _count, _] = block
            validateHash(hash, map)
        end)

    end

    def initializeGenesisBlock(numNodes, nbits) do
        :ets.new(:table, [:bag, :named_table,:public])
        SSUPERVISOR.start_link(numNodes)
        firstBlock = BLOCKCHAIN.createGenesisBlock(nbits)
        :ets.insert(:table,{"Blocks",1,firstBlock})
    end

    def testSetup() do
        numNodes = 8
        nbits = BLOCKCHAIN.calculateNBits()
        BLOCKCHAIN.initializeGenesisBlock(numNodes,nbits)
        transferAmt = Enum.random(1..24)
        noOfTrans = 2
        noMiners = 2
        Enum.each(1..noMiners, fn _-> MINERSERVER.start_link end)
        TRANSACTION.createInitialTransactions(transferAmt, noOfTrans, nbits)
    end

    def validateMerkleRoot(list) do
        Enum.all?(list, fn {_,_,block} ->
            [_, map, _count, tList] = block
            MINERSERVER.validateMerkleRoot(Map.get(map,:merkleRoot), tList)
            end)
    end
  end
