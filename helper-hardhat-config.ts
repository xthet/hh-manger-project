export const developmentChains:string[] = ["hardhat", "localhost"]

interface networkConfig {
  [keyof: number] : {
    name: string
    linkTokenAddress: string
    registrarAddress: string
    registryAddress: string
    upkeepCreatorAddress: string
  }
}

export const networkConfig:networkConfig = {
  5: {
    name: "goerli",
    linkTokenAddress: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    registrarAddress: "0x9806cf6fBc89aBF286e8140C42174B94836e36F2",
    registryAddress: "0x02777053d6764996e594c3E88AF1D58D5363a2e6",
    upkeepCreatorAddress: "0x03CC2EAADa02326133B8D137cDc996013B16fFd0"
  },

  43113: {
    name: "fuji",
    linkTokenAddress: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
    registrarAddress: "0x57A4a13b35d25EE78e084168aBaC5ad360252467",
    registryAddress: "0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2",
    upkeepCreatorAddress: "0xE8Db971CF3693154167431D389CA58d7D7917dC1"
  }
}