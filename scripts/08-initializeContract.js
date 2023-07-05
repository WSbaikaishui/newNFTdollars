const {readAddressList,storeAddressList} = require('./help');
const { ethers, run, network } = require("hardhat")
const {address} = require("hardhat/internal/core/config/config-validation");

async function main() {
    addressList = readAddressList();
    //initial


    uintLayerAddress = ["0xc8adfb4d437357d0a656d4e62fd9a6d22e401aa0",
        "0x6632a9d63e142f17a668064d41a21193b49b41a0",
        "0x32973908faee0bf825a343000fe412ebe56f802a",
        "0x6be69b2a9b153737887cfcdca7781ed1511c7e36",
        "0x7ea3cca10668b8346aec0bf1844a49e995527c8b",
        "0x7ecb204fed7e386386cab46a1fcb823ec5067ad5",
        "0xb4d06d46a8285f4ec79fd294f78a881799d8ced9",
        "0x0cfb5d82be2b949e8fa73a656df91821e2ad99fd",
        "0x160c404b2b49cbc3240055ceaee026df1e8497a0",
        "0x67d9417c9c3c250f61a83c7e8658dac487b56b09",
        "0x8943c7bac1914c9a7aba750bf2b6b09fd21037e0",
        "0x123b30e25973fecd8354dd5f41cc45a3065ef88c",
        "0x86c10d10eca1fca9daf87a279abccabe0063f247",
        "0xca7ca7bcc765f77339be2d648ba53ce9c8a262bd",
        "0xd78b76fcc33cd416da9d3d42f72649a23d7ac647",
        "0x219b8ab790decc32444a6600971c7c3718252539",
        "0x9a534628b4062e123ce7ee2222ec20b86e16ca8f",
        "0x036721e5a769cc48b3189efbb9cce4471e8a48b1",
        "0x4db1f25d3d98600140dfc18deb7515be5bd293af",
        "0x75e95ba5997eb235f40ecf8347cdb11f18ff640b",
        "0xc1caf0c19a8ac28c41fe59ba6c754e4b9bd54de9",
        "0xc3f733ca98e0dad0386979eb96fb1722a1a05e69",
        "0xf4ee95274741437636e748ddac70818b4ed7d043",
        "0x466cfcd0525189b573e794f554b8a751279213ac",
        "0x524cab2ec69124574082676e6f654a18df49a048",
        "0x0b4b2ba334f476c8f41bfe52a428d6891755554d",
        "0x0c2e57efddba8c768147d1fdf9176a0a6ebd5d83",
        "0x7ab2352b1d2e185560494d5e577f9d3c238b78c5",
        "0x9378368ba6b85c1fba5b131b530f5f5bedf21a18",
        "0xb5c747561a185a146f83cfff25bdfd2455b31ff4",
        "0x1b829b926a14634d36625e60165c0770c09d02b2",
        "0xd2f668a8461d6761115daf8aeb3cdf5f40c532c6",
        "0x2acab3dea77832c09420663b0e1cb386031ba17b",
        "0xa1d4657e0e6507d5a94d06da93e94dc7c8c44b51",
        "0xf54cc94f1f2f5de012b6aa51f1e7ebdc43ef5afc",
        "0x19b86299c21505cdf59ce63740b240a9c822b5e4",
        "0x3110ef5f612208724ca51f5761a69081809f03b7",
        "0xc92ceddfb8dd984a89fb494c376f9a48b999aafc",
        "0x4b61413d4392c806e6d0ff5ee91e6073c21d6430",
        "0xc2c747e0f7004f9e8817db2ca4997657a7746928",
        "0xd532b88607b1877fe20c181cba2550e3bbd6b31c",
        "0xfcb1315c4273954f74cb16d5b663dbf479eec62e",
        "0xf61f24c2d93bf2de187546b14425bf631f28d6dc",
        "0xe0176ba60efddb29cac5b15338c9962daee9de0c"]
    crossLayerAddress = [
        "0x59468516a8259058bad1ca5f8f4bff190d30e066",
        "0x5af0d9827e0c53e4799bb226655a1de152a425a5",
        "0x60bb1e2aa1c9acafb4d34f71585d7e959f387769",
        "0x39ee2c7b3cb80254225884ca001f57118c8f21b6",
        "0x3bf2922f4520a8ba0c2efc3d2a1539678dad5e9d",
        "0x4b15a9c28034dc83db40cd810001427d3bd7163d",
        "0x364c828ee171616a39897688a831c2499ad972ec",
        "0xccc441ac31f02cd96c153db6fd5fe0a2f4e6a68d",
        "0x521f9c7505005cfa19a8e5786a9c3c9c9f5e6f42",
        "0xbd4455da5929d5639ee098abfaa3241e9ae111af",
        "0x09233d553058c2f42ba751c87816a8e9fae7ef10",
        "0xe785e82358879f061bc3dcac6f0444462d4b5330",
        "0x79fcdef22feed20eddacbb2587640e45491b757f",
        "0x7d8820fa92eb1584636f4f5b8515b5476b75171a",
        "0xb852c6b5892256c264cc2c888ea462189154d8d7",
        "0x5cc5b05a8a13e3fbdb0bb9fccd98d38e50f90c38",
        "0x80336ad7a747236ef41f47ed2c7641828a480baa",
        "0x892848074ddea461a15f337250da3ce55580ca85",
        "0x1792a96e5668ad7c167ab804a100ce42395ce54d",
        "0xc99c679c50033bbc5321eb88752e89a93e9e83c5",
        "0x231d3559aa848bf10366fb9868590f01d34bf240",
        "0x57a204aa1042f6e66dd7730813f4024114d74f37",
        "0x394e3d3044fc89fcdd966d3cb35ac0b32b0cda91",
        "0x1cb1a5e65610aeff2551a50f76a87a7d3fb649c6",
        "0x77372a4cc66063575b05b44481f059be356964a4",
        "0x960b7a6bcd451c9968473f7bbfd9be826efd549a",
        "0x1a92f7381b9f03921564a437210bb9396471050c",
        "0x3903d4ffaaa700b62578a66e7a67ba4cb67787f9"
    ]
    reserviorLayerAddress = ["0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d",
        "0xbd3531da5cf5857e7cfaa92426877b022e612cf8",
        "0x49cf6f5d44e70224e2e23fdcdd2c053f30ada28b",
        "0xb7f7f6c52f2e2fdb1963eab30438024864c313f6",
        "0x60e4d786628fea6478f785a6d7e704777c86a7c6",
        "0x23581767a106ae21c074b2276d25e5c3e136a68b",
        "0xed5af388653567af2f388e6224dc7c4b3241c544",
        "0xba30e5f9bb24caa003e9f2f0497ad287fdf95623",
        "0x8a90cab2b38dba80c64b7734e58ee1db38b8992e"]

    uintLayerName =["CryptoBatz by Ozzy Osbourne",
        "Prime Ape Planet",
        "Pixelmon",
        "Killer GF",
        "CyberKongz VX",
        "FULL SEND METACARD",
        "3Landers",
        "10KTF",
        "PXN: Ghost Division",
        "Phanta Bear",
        "Lazy Lions",
        "alien frens",
        "Cool Pets",
        "tubby cats by tubby collective",
        "Lil Heroes",
        "Sneaky Vampire Syndicate",
        "MekaVerse",
        "Checks - VV Originals",
        "HAPE PRIME",
        "Psychedelics Anonymous Genesis",
        "CryptoSkulls",
        "Official MoonCats - Acclimated",
        "The Doge Pound",
        "Dooplicator",
        "LilPudgys",
        "JRNY NFT Club",
        "KaijuKingz",
        "Adam Bomb Squad",
        "VeeFriends Series 2",
        "Boss Beauties",
        "Treeverse",
        "Karafuru",
        "DeadFellaz",
        "WebbLand",
        "Nanopass",
        "DEGEN TOONZ COLLECTION",
        "Impostors Genesis Aliens",
        "Creature World",
        "MURI by Haus",
        "Hashmasks",
        "SuperNormalbyZipcy",
        "Capsule",
        "World of Women Galaxy",
        "PREMINT Collector Pass - OFFICIAL"]
    crossLayerName = ["Invisible Friends",
        "Milady",
        "Art Gobblers",
        "The Potatoz",
        "0N1 Force",
        "HV-MTL",
        "Sappy Seals",
        "FLUF",
        "ForgottenRunesWizardsCult",
        "NFT Worlds",
        "My Pet Hooligan",
        "World Of Women",
        "mfer",
        "Murakami.Flowers Official",
        "rektguy",
        "Sandbox's LANDs",
        "Chimpers",
        "CyberBrokers",
        "Moonbirds Oddities",
        "KILLABEARS",
        "Valhalla",
        "CyberKongz",
        "RENGA",
        "Cryptoadz",
        "a KID called BEAST",
        "OnChainMonkey",
        "Cool Cats",
        "Quirkies Originals"]
    reserviorLayerName = ["Bored Ape Yacht Club",
        "PudgyPenguins",
        "CloneX",
        "Wrapped Cryptopunks",
        "MutantApeYachtClub",
        "Moonbirds",
        "Azuki",
        "Bored Ape Kennel Club",
        "Doodles"]
    //initial nfusd token
    const nftusdToken = await ethers.getContractFactory("NFTUSDToken")
    const nftusd = nftusdToken.attach(addressList["NFTUSDToken"]);


    //initial ndl token
    const ndlToken = await ethers.getContractFactory("NDLToken")
    const ndl = ndlToken.attach(addressList["NDLToken"]);


    //initial nftoracle token
    const nftOracle = await ethers.getContractFactory("NFTOracle")
    const nftoracle = nftOracle.attach(addressList["NFTOracle"]);


    //initial loanpool token
    const LoanPool = await ethers.getContractFactory("LoanPool")
    const loanPool = LoanPool.attach(addressList["LoanPool"]);



    // await nftusd.initializePool(addressList["StabilityPool"]);
    // console.log("NFTUSDToken is initialized successfully")

//     const tx1 =await ndl.initialize(addressList["LockupContract"]);
//     await tx1.wait();
//     console.log("Ndl is initialized successfully")
//     const tx2 = await ndl.initializePool(addressList["StabilityPool"]);
//     await tx2.wait();
//     const tx3 = await ndl.transfer("0xc7ae166404DfA77D2AF214e04Bb8B930274A02b8", "10000000000000000000000");
//     await tx3.wait();
//     console.log("NDLToken is initializePool successfully  0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162")
//
//
//     const tx4 = await nftoracle.initialize(
//         "0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162",
//         200000000000,
//         100000000000,
//         1800,
//         600,
//         600);
//     await tx4.wait();
//     console.log("NFTOracleToken is initialized successfully")
//     const txtype1 = await  nftoracle.setAssets(
//         reserviorLayerAddress,
// reserviorLayerName,
//         reserviorLayerName,
//         reserviorLayerName,
//         2
//     )
//     await txtype1.wait();
//     const txtype2 = await  nftoracle.setAssets(
//         crossLayerAddress,
//         crossLayerName,
//         crossLayerName,
//         crossLayerName,
//     1   )
//     await txtype2.wait();
//     const txtype3 = await  nftoracle.setAssets(
//         uintLayerAddress,
//         uintLayerName,
//         uintLayerName,
//         uintLayerName,
//         0
//     )
//     await txtype3.wait();
    const tx5 = await nftoracle.addAsset(
        "0xE2AF2a4CEb57B6b7BfBE350e9daC59be9d402F1A",
        "GameItem",
        "ITM",
        "helloWorld",
        1
    )
    await tx5.wait();
    console.log("NFTOracleToken is addAsset successfully")
    const tx6 = await nftoracle.setAssetData(
        "0xE2AF2a4CEb57B6b7BfBE350e9daC59be9d402F1A",
        100000,
        20,
        2900)
    await tx6.wait();
    console.log("NFTOracleToken is setAssetData successfully")


    const tx7 = await loanPool.initialize(addressList["StabilityPool"]);
    await tx7.wait();
    console.log("LoanPoolToken is initialized successfully")


//initial stabilitypool token
    const StabilityPool = await ethers.getContractFactory("StabilityPool")
    const stabilityPool = StabilityPool.attach(addressList["StabilityPool"]);

   const tx8 =  await stabilityPool.initialize(nftoracle.address,nftusd.address,ndl.address,loanPool.address);
   await tx8.wait();

   const tx9 = await stabilityPool.setThreshold(1,"100000000000000000000")
    await tx9.wait();
   const tx10 = await stabilityPool.setThreshold(2,"500000000000000000000")
    await tx10.wait();
    const tx11 = await stabilityPool.setThreshold(3,"1000000000000000000000")
    await tx11.wait();
    console.log("StabilityPoolToken is initialized successfully")


}



//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )