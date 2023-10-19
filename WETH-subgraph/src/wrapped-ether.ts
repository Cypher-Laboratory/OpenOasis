import { BigInt } from "@graphprotocol/graph-ts";
import {
	Approval as ApprovalEvent,
	Deposit as DepositEvent,
	EIP712DomainChanged as EIP712DomainChangedEvent,
	Transfer as TransferEvent,
	Withdrawal as WithdrawalEvent,
} from "../generated/WrappedEther/WrappedEther";
import { Approval, Deposit, EIP712DomainChanged, Transfer, Withdrawal, AddressBalance } from "../generated/schema";

function getAddressBalance(id: string): AddressBalance {
	let addressBalance = AddressBalance.load(id);

	if (addressBalance == null) {
		addressBalance = new AddressBalance(id);
		addressBalance.balance = BigInt.fromI32(0);
	}

	return addressBalance as AddressBalance;
}

export function handleApproval(event: ApprovalEvent): void {
	let entity = new Approval(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.owner = event.params.owner;
	entity.spender = event.params.spender;
	entity.value = event.params.value;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	entity.save();
}

export function handleDeposit(event: DepositEvent): void {
	let entity = new Deposit(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.dst = event.params.dst;
	entity.wad = event.params.wad;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	entity.save();
}

export function handleEIP712DomainChanged(event: EIP712DomainChangedEvent): void {
	let entity = new EIP712DomainChanged(event.transaction.hash.concatI32(event.logIndex.toI32()));

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	entity.save();
}

export function handleTransfer(event: TransferEvent): void {
	let entity = new Transfer(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.from = event.params.from;
	entity.to = event.params.to;
	entity.value = event.params.value;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	entity.save();

	// Update balances
	let senderBalance = getAddressBalance(event.params.from.toHex());
	senderBalance.balance = senderBalance.balance.minus(event.params.value);
	senderBalance.save();

	let recipientBalance = getAddressBalance(event.params.to.toHex());
	recipientBalance.balance = recipientBalance.balance.plus(event.params.value);
	recipientBalance.save();
}

export function handleWithdrawal(event: WithdrawalEvent): void {
	let entity = new Withdrawal(event.transaction.hash.concatI32(event.logIndex.toI32()));
	entity.src = event.params.src;
	entity.wad = event.params.wad;

	entity.blockNumber = event.block.number;
	entity.blockTimestamp = event.block.timestamp;
	entity.transactionHash = event.transaction.hash;

	entity.save();

	// Update balance
	let withdrawerBalance = getAddressBalance(event.params.src.toHex());
	withdrawerBalance.balance = withdrawerBalance.balance.minus(event.params.wad);
	withdrawerBalance.save();
}

