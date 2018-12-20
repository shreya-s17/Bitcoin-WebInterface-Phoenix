defmodule GENSERVERS do
    use GenServer
  
    def start_link(_) do
      [privateKey, publicKey] = KEYGENERATION.generate()
      :ets.insert(:table, {"PublicKeys", KEYGENERATION.to_public_hash(publicKey)})
      GenServer.start_link(__MODULE__,[privateKey,publicKey,0],
          name: String.to_atom("h_" <> KEYGENERATION.to_public_hash(publicKey)))
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
  end
  