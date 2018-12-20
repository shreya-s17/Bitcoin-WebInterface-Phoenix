defmodule BitcoinWeb.LayoutView do
  use BitcoinWeb, :view
  
  def chart(conn) do
    
    case conn.assigns[:chart] do
      chart -> chart
    end
  end
end
