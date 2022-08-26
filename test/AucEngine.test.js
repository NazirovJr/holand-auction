const { time } = require("@nomicfoundation/hardhat-network-helpers")
const {expect} = require("chai")
const {ethers} = require("hardhat")


describe("AucEngine", function() {
    let owner
    let seller
    let buyer
    let auct

    beforeEach(async function() {
        [owner, seller, buyer] = await ethers.getSigners();
        const AucEngine = await ethers.getContractFactory("AucEngine", owner);
        auct = await AucEngine.deploy();
        await auct.deployed();
    })

    it("sets owner", async function() {
        const currentOwner = await auct.owner()
        expect(currentOwner).to.eq(owner.address)
    })

    async function getTimestamp(bn) {
        return (
            await ethers.provider.getBlock(bn)
        ).timestamp
    }

    describe("createAuction", function() {
        it("create auction correctly", async function() {
            const duration = 60

            const tx = await auct.createAuction(
                ethers.utils.parseEther("0.001"),
                3,
                "fake item",
                duration
            )

            const cAuction = await auct.auctons(0)
            const ts = await getTimestamp(tx.blockNumber)
            await expect(cAuction.startingPrice).to.eq(ethers.utils.parseEther("0.001"))
            await expect(cAuction.item).to.eq("fake item")
            await expect(cAuction.endsAt).to.eq(ts + duration)
        })
    }),

  

    describe("buy", function() {
        
        async function delay(ms) {
            return new Promise(resolve => setTimeout(resolve, ms))
        }

        it("allows to buy", async function() {
                const duration = 60
                const tx = await auct.connect(seller).createAuction(
                    ethers.utils.parseEther("0.0001"),
                    3,
                    "fake item",
                    duration
                )
            
                this.timeout(5000)
                await delay(1000)

                const buyTx = await auct.connect(buyer).buy(0,{value:ethers.utils.parseEther("0.0001")})
                const cAuction = await auct.auctons(0)
                const finalPrice = cAuction.finalPrice

                await expect(() => buyTx)
                .to.changeEtherBalance(seller, finalPrice - Math.floor((finalPrice * 10) / 100) - 2)

                await expect(buyTx)
                .to.emit(auct, "AuctionEnded")
                .withArgs(0, finalPrice - 3,  buyer.address)

                await expect(
                    auct.connect(buyer).buy(0,{value:ethers.utils.parseEther("0.0001")}))
                    .to.be.revertedWith("stopped!")
        
            })
        })
})

