# Bitcoin Web Interface

## Group info
| Name  | UFID  |
|---|---|
| Amruta Basrur | 44634819  |
|  Shreya Singh| 79154462  |

## Instructions
To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Statistics
* **Total number of bitcoins mined** <br>
    This is the statistics for the total number of bitcoins which have been mined in the network.
* **Total number of Transactions confirmed** <br>
   This shows the total number of transactions which have been added to the block chain network and have become immutable. This includes all the transactions including the coin base transaction.
* **Total number of Transactions in pending** <br>
   This statistic shows the total number of transactions which are in the memory pool towards the end of the program when all the coins have been mined. The ideal value is 0 since no transaction should be left pending with the end of the program. 

## Graphs & tests 
  * **Bitcoins in circulation** <br>
  This graph shows the total number of bitcoins which are in circulation. The graph is expected to increase with the ongoing time. 

  * **Size of Blockchain vs time** <br>
    This graph draws a straight increasing line with time. Since it is expected that the size of the block chain should increase with time as more and more blocks are added to it. The similar test case also checks the number of blocks in the blockchain at a particular time. 
  * **Number of Transactions vs time** <br>
  This graph shows the total number of transactions with time which are expected to increase almost linearly as in our case. The total number of transactions include the total number of unspent and pending transactions with time. As shown by the graph the transactions increase with time. 
  * **Number of Transactions vs Block** <br>
  This graph shows the total number of transactions with each block. Since there are different possibilities of number of transactions which have been combined to solve for the difficulty target and hence different number of transactions are present in each block. This graph as expected has variable length which is random and depending upon the total number of transactions which reach the hash difficulty target.
  * **Mining Revenue** <br> 
  This graph shows the total mining rewards with respect to each block. Since, whenever a miner mines a particular block, the reward goes to him. As expected in the real life bitcoin the miner rewards have seen a reduction in amount with time. Out graph displays the slight decreasing curve with some amount of random behavour. 
  * **Total Transaction Fee paid to miners** <br>
  This graph shows the decreasing value of the total transaction fees which needs to be paid to the miner with each transaction and each increasing transaction as the size of network increases. 
  * **Cost percentage of Transaction Volume** <br> 
  This graph shows the total number of transactions which a miner mines in a block with respect to the total revenue which is generated for him. The mining rewards are expected to be decreasing with time. Though the graph of number of transactions with mining revenue is absolutely random and depends upon the amount of transaction fee in it. Since this is being generated at random the graph shows randomness as expected. 
  * **Transaction value with time** <br>
 This graph shows the amounts for which the transactions are created in the network. This graph shows a random behaviour since the transaction value which a node picks up to send to the reciever is random.
