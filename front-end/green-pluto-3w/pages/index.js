import { ConnectWallet } from "@thirdweb-dev/react";
import styles from "../styles/Home.module.css";
import ChainContext from "../context/chain";
import { useContext } from "react";
import dynamic from 'next/dynamic';

export default function Home() {

  const { selectedChain, setSelectedChain } = useContext(ChainContext);
  const IDKitWidget = dynamic(() => import('@worldcoin/idkit').then(mod => mod.IDKitWidget), { ssr: false })

  return (
    <div className={styles.container}>
      <main className={styles.main}>
        <h1 className={styles.title}>
          Welcome to <span>Green Pluto AI algo trading game</span>!
        </h1>

        <div className={styles.description}>
        <img 
        src="../green-pluto.png" // Path to your image
        alt="Logo" // Alternative text for the image

      />
          
        </div>

        <p className={styles.description}>
          The ultimate game to bet on trading algos and new kind of financial derivative<br />
          <ul className={styles.list}>
            <li>All algos compete in making profits in the same crypto assets</li>
            <li>The backers of the winning algo earn the principle of other algo backers</li>
            <li>If your chosen algo earns money, you will always keep the earnings</li>
            <li>This is a variation of binary derivatives gamifyied</li>
          </ul>
          
        </p>
        {/*
        <select
          value={String(selectedChain)}
          onChange={(e) => setSelectedChain(e.target.value)}
        >
          <option value="ethereum">Mainnet</option>
          <option value="goerli">Goerli</option>
        </select>*/}

        <div className={styles.connect}>
          <ConnectWallet />
        </div>

        <div className={styles.worldcoin}>
        <p className={styles.description_small}> Worldcoin widget (app_id not available from developer.worldcoin.org): </p>
        <IDKitWidget
          app_id="app_BPZsRJANxct2cZxVRyh80SFG" // obtain this from developer.worldcoin.org
          action="my_action"
          enableTelemetry
          onSuccess={result => console.log(result)} // pass the proof to the API or your smart contract
        /> 
        </div>

        <div className={styles.grid}>
          <a href="bet1" className={styles.card}>
            <h2>Bet on Algo 1 &rarr;</h2>
            <p>
              Algo 1 always goes long only at the beginning of the period and does not do any transactions.
            </p>
            <button className={styles.betButton}>Bet</button>
          </a>

          <a href="bet2" className={styles.card}>
            <h2>Bet on Algo 2 &rarr;</h2>
            <p>
              Algo 2 is state of the art LSTM neural net model capable of moving in and out of positions.
            </p>
            <button className={styles.betButton}>Bet</button>
          </a>

          <a
            href="bet3"
            className={styles.card}
          >
            <h2>Bet on Algo 3 &rarr;</h2>
            <p>
              Algo 3 is based on traditional technical analysis, observing moving avarages, stochastics and other indicators.
            </p>
            <button className={styles.betButton}>Bet</button>
          </a>

          <a href="bet4" className={styles.card}>
            <h2>Bet on Algo 4 &rarr;</h2>
            <p>
              Algo 4 is does not do anything. This bet will win if the other algos lose money.
            </p>
            <button className={styles.betButton}>Bet</button>
          </a>
        </div>
      </main>
    </div>
  );
}
