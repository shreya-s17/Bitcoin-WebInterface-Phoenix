defmodule TASKFINDER do
  import Ecto
  import Ecto.Changeset
  import Ecto.Query  
  use Task

    require MINERSERVER
    alias Bitcoin.Repo
    alias Bitcoin.Blocks
    alias Bitcoin.Transactions
    @miningValue 25
  
    def run(no,nbits,count) do
      list = :ets.lookup(:table, "pendingTxns")
  #IO.inspect Enum.count(list)
      if(Enum.count(list) >0) do
        tempList = Enum.sort(list, &(Kernel.elem(&1,2) <= Kernel.elem(&2,2)))
        nlist = Enum.map(tempList, fn {_,x,y,z} -> {x,y,z} end)
        #IO.inspect nlist
        removeList = MINERSERVER.validateTransaction(Enum.slice(nlist,1..-1))
        tempList = Enum.filter(tempList, fn {_,x,y,z} -> !Enum.member?(removeList,{x,y,z}) end)
        :ets.delete(:table,"pendingTxns")
        Enum.each(list, fn {_,x,y,z}-> if(!Enum.member?(removeList,{x,y,z})) do
          :ets.insert(:table,{"pendingTxns", x,y,z})
        end
      end)
  
  
        count = Enum.count(tempList)
        pow = :math.pow(2,countList(0,count))
        count = if(pow==count || pow+1==count) do
                  count
                else
                  pow+1
                end
        list = Enum.slice(tempList,0..round(count))
        minerFee = Enum.reduce(list,0, fn {_,_,x,_}, acc-> acc+x end)
        miners = :ets.lookup(:table,"MinerPublicKeys")
        tasksList = Enum.map(miners, fn {_,x}->
          Task.async(fn -> startMining(list, "m_" <> x, minerFee,nbits) end)
        end)
        await(tasksList,no,nbits, count,minerFee)
        Process.sleep(500)
        run(no+1,nbits, count)
      else
        if(count<5) do
        run(no+1,nbits, count+1)
        end
      end
  
    end
  
    def await(tasks,no,nbits,count,minerFee) do
      receive do
        message ->
          case Task.find(tasks, message) do
            {:fail, task} ->
              await(List.delete(tasks, task),no,nbits,count, minerFee)
            {block, task} ->
              Enum.each(List.delete(tasks, task),fn x -> Task.shutdown(x) end)
              miners = :ets.lookup(:table,"MinerPublicKeys")
              val = Enum.all?(miners, fn {_,x} ->
               GenServer.call(String.to_atom("m_"<>x), {:validateBlock, block, no})
              end)
              if(val) do
                :ets.insert(:table,{"Blocks",no,block})
                map=%{blockNo: no, blockId: Enum.at(block,0), reward: @miningValue+minerFee, transCount: Enum.count(Enum.at(block,3))}
                struct(Blocks, map) |> Repo.insert
                insertUnspentTxns(Enum.at(block,3))
                #IO.inspect :ets.lookup(:table, "Blocks")
              else
                run(no,nbits,count)
              end
            nil ->
              await(tasks,no,nbits,count, minerFee)
          end
      end
    end
  
  def startMining(nList,miner, minerFee,nbits) do
    if(Enum.count(nList)>0) do
      BLOCKCHAIN.createBlockHeader(miner, nList, @miningValue, minerFee, BLOCKCHAIN.getLatestBlock(),nbits)
    else
      :fail
    end
  end
  
  def countList(i,count) do
    if(:math.pow(2,i) > count) do
      i-1
    else
      countList(i+1,count)
    end
  end
  
  def insertUnspentTxns(list) do
    tList = :ets.lookup(:table,"pendingTxns")
    :ets.delete(:table,"pendingTxns")
    Enum.each(tList, fn x->
      if(!Enum.member?(list, Tuple.delete_at(x,0))) do
        {_,a,b,c} =x
      :ets.insert(:table,{"pendingTxns",a,b,c})
      end
    end)
  
    tList = :ets.lookup(:table,"unspentTxns")
    :ets.delete(:table,"unspentTxns")
    txIdList = Enum.reduce(list, [], fn {_,_,map}, acc ->
      acc ++ Map.get(map, :inputTxIds) end)
    Enum.each(tList, fn {_,x,b,c}->
      if(!Enum.member?(txIdList, x)) do
      :ets.insert(:table,{"unspentTxns",x,b,c})
      end
    end)
   # Process.sleep(9000)
    Enum.each(list, fn {x,y,z}-> 
      :ets.insert(:table,{"unspentTxns",x,y,z}) 
      #c = Ecto.Changeset.put_change(b, )
      #Repo.update(b)
  end)
   # IO.inspect :ets.lookup(:table,"unspentTxns")




   
  end
  
  end
  