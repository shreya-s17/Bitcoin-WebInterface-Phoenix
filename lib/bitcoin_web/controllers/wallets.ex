defmodule WALLETS do
    require GENSERVERS

    def updateUnspentAmount() do
      list = :ets.lookup(:table,"unspentTxns")
      Enum.each(list, fn {_,_,_,x} ->
        {ipKey,val} = Map.get(x,:inputs)
        if(ipKey !="0") do
          GenServer.cast(String.to_atom("h_" <> ipKey), {:updateWallet, (val)*-1})
        end
        opList = Map.get(x,:outputs)
        pubKeys = :ets.lookup(:table,"PublicKeys")
        pubKeys = Enum.map(pubKeys, fn {_,x}-> x end)

        Enum.each(opList, fn [pubKey,amt]->
            if(Enum.member?(pubKeys,pubKey)) do GenServer.cast(String.to_atom("h_" <> pubKey),
              {:updateWallet, amt})
            else GenServer.cast(String.to_atom("m_" <> pubKey), {:updateWallet, amt}) end
        end)
      end)
    end

    def verify_signature(public_key, msg, signature) do
      sig = Base.decode16!(signature)
      pk = Base.decode16!(public_key)
      :crypto.verify(:ecdsa, :sha256, msg, sig, [pk, :secp256k1])
    end

    def getUnspentTxns(pubKey, transferAmt) do
      list = :ets.lookup(:table,"unspentTxns")
      inputs = Enum.filter(list, fn {_,_,_,map}->
        Enum.member?(Enum.map(Map.get(map,:outputs), fn [pKey,_mt]-> pKey end), pubKey)
      end)
        getInputs(inputs,0,transferAmt,0,[])
    end

    def getInputs(inputs,i,transferAmt,sum,list) do
        if(i<Enum.count(inputs)) do
            {_,txid,_,map} = Enum.at(inputs,i)
            amount = Enum.map(Map.get(map,:outputs), fn [_pKey,amt]-> amt end)
            tamount = Enum.sum(amount)
            sum = sum+tamount
            if(sum < transferAmt) do
                list = list ++ [[Enum.at(inputs,i),txid,tamount,sum]]
                getInputs(inputs,i+1,transferAmt,sum, list )
            else
                list ++ [[Enum.at(inputs,i),txid,tamount,sum]]
            end
        else
            NULL
        end
    end

    def getOutputs(amount, transferAmt, hashList, address1) do
      if(transferAmt > amount) do :ets.insert("Error",
        {"Amount transfer is greater than present amount"}) end
      list = if(amount - transferAmt > Float.round(0.1 * transferAmt, 4)) do
        {[[Enum.random(hashList), transferAmt],
        [address1, amount - transferAmt - 0.1 * transferAmt]], Float.round(0.1 * transferAmt, 4)}
    else
        if(amount - transferAmt - 0.1 * transferAmt >=0) do
        {[[Enum.random(hashList), transferAmt]], Float.round(0.1 * transferAmt, 4)}
        else
          {[[Enum.random(hashList), transferAmt]], amount - transferAmt}
        end
      end
      list
    end

    def getAllStates() do
      #IO.puts "amruta"
      list =  :ets.lookup(:table,"PublicKeys")
      |> Enum.map(fn {_, x}->
          [_,_,amt] = GenServer.call(String.to_atom("h_" <> x), {:getState})
          amt
      end)
      list
    end
  end
