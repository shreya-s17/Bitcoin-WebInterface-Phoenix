defmodule MINERSERVER do
    use GenServer

    def start_link do
      [privateKey, publicKey] = KEYGENERATION.generate()
      :ets.insert(:table, {"MinerPublicKeys", KEYGENERATION.to_public_hash(publicKey)})
      GenServer.start_link(__MODULE__,[privateKey,publicKey,0],
        name: String.to_atom("m_" <> KEYGENERATION.to_public_hash(publicKey)))
    end

    def init(state) do
        Process.flag(:trap_exit, true)
        {:ok, state}
    end

    def handle_cast({:updateWallet, amount}, state) do
        [private, public, unspent] = state
        state = [private, public, unspent + amount]
        {:noreply, state}
      end

    def handle_call({:getState}, _from, state) do
        {:reply, state, state}
    end

    def handle_call({:validateBlock, block, no}, _from, state) do
        [hash, map, _count, tList] = block
        list = :ets.lookup(:table,"Blocks")
        result = if(validateBlockChain(Map.get(map,:previousBlockHash), no, 0, list) && BLOCKCHAIN.validateHash(hash, map)
         && (Enum.count(validateTransaction(tList)) != 0) && validateMerkleRoot(Map.get(map,:merkleRoot), tList)) do

            :true
        else
            #IO.puts(" aaaaaaammmmmmmm #{inspect validateBlockChain(Map.get(map,:previousBlockHash), no, 0, list)}
            #{inspect BLOCKCHAIN.validateHash(hash, map)}
            #{inspect validateTransaction(tList)}
            #{inspect validateMerkleRoot(Map.get(map,:merkleRoot), tList)}")
            :false end
        {:reply, result,state}
    end

    def validateBlockChain(phash, no, pno,list) do
        if(pno==0) do true
        else
            {_,pno1,[phash1,map,_,_]} = Enum.at(list,pno-1)
            if(phash1 ==phash && no ==pno1-1) do
                validateBlockChain(Map.get(map,:previousBlockHash), pno1, pno1-1, list)
            else false end
        end
    end

    def validateMerkleRoot(merkleRoot, list) do
        newList = Enum.map(list, fn {x,_,_} -> x end)
        if(BLOCKCHAIN.calculateMerkleRoot(newList,0) == merkleRoot) do true
        else false end
    end

    def validateOnlyOneCoinbase(tList) do
        Enum.reduce(tList,[], fn {a,b,map}, acc ->
            out = if(Enum.any?(Map.get(map,:outputs), fn [_,x]->
                #IO.inspect(x)
                x == 0 end)) do
                :ets.insert(:table, {"Error", "Handled condition- 0 output amount not accepted in block"})
                IO.puts "Handled condition- 0 output amount not accepted in block"
                acc ++ {a,b,map}
            else
                 [] end
            out
        end)
    end

    def validateTransaction(tList) do
        list =validateOnlyOneCoinbase(tList)

        list1 = Enum.map(tList, fn {a,b,map} ->
            {_,inputs} = Map.get(map, :inputs)
            outputs = Enum.reduce(Map.get(map, :outputs),0, fn [_,x],acc-> acc + x end)
            transFee = b
            out = if(inputs > outputs+transFee) do
                :ets.insert(:table, {"Error", "Outputs greater than inputs"})
                IO.puts("Outputs greater than inputs #{inspect inputs} #{inspect transFee} #{inspect outputs}")
                {a,b,map}
            else [] end
            out
        end)
        [list | list1]
     end

     def existsTransactions(list) do
        validateTransactionList(list)
     end

     def validateEntireBlockChain(list) do
        {_,no,[_, map, _count, _]} = Enum.at(list,-1)
        if(validateBlockChain(Map.get(map,:previousBlockHash), no, 0, list)) do
            true
        else false
    end
    end

    def validateTransactionList(bList) do
        Enum.all?(bList, fn {_,_,[_,_,_,list]} ->
        Enum.all?(validateTransaction(Enum.slice(list,1..-1)), fn x-> x==[] end)
    end)
     end

  end
