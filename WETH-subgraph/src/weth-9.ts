import { Approval as ApprovalEvent, Transfer as TransferEvent, Deposit as DepositEvent, Withdrawal as WithdrawalEvent } from "../generated/WETH9/WETH9";
import { Approval, Transfer, Deposit, Withdrawal, AddressBalance } from "../generated/schema";
import { BigInt, Bytes } from "@graphprotocol/graph-ts";

function getOrCreateAddressBalance(address: string): AddressBalance {
	let addressBytes = Bytes.fromHexString(address).toHexString() as string;
	let balance = AddressBalance.load(addressBytes);

	if (balance == null) {
		balance = new AddressBalance(addressBytes);
		balance.balance = BigInt.fromI32(0);
	}

	return balance as AddressBalance;
}

export function handleApproval(event: ApprovalEvent): void {
	let entity = new Approval(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.src = event.params.src;
	entity.guy = event.params.guy;
	entity.wad = event.params.wad;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	entity.save();
}

export function handleTransfer(event: TransferEvent): void {
	let entity = new Transfer(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.src = event.params.src;
	entity.dst = event.params.dst;
	entity.wad = event.params.wad;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	let srcBalance = getOrCreateAddressBalance(event.params.src.toHex());
	let dstBalance = getOrCreateAddressBalance(event.params.dst.toHex());

	srcBalance.balance = srcBalance.balance.minus(event.params.wad);
	dstBalance.balance = dstBalance.balance.plus(event.params.wad);

	srcBalance.save();
	dstBalance.save();

	entity.save();
}

export function handleDeposit(event: DepositEvent): void {
	let entity = new Deposit(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.dst = event.params.dst;
	entity.wad = event.params.wad;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	let balance = getOrCreateAddressBalance(event.params.dst.toHex());

	balance.balance = balance.balance.plus(event.params.wad);

	balance.save();

	entity.save();
}

export function handleWithdrawal(event: WithdrawalEvent): void {
	let entity = new Withdrawal(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.src = event.params.src;
	entity.wad = event.params.wad;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	let balance = getOrCreateAddressBalance(event.params.src.toHex());

	balance.balance = balance.balance.minus(event.params.wad);

	balance.save();

	entity.save();
}

