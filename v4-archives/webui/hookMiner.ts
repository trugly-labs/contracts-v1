import { getContractAddress, toBytes, concat, numberToHex } from "viem";
import OinkOinkArtifact from "../../out/OinkOink.sol/OinkOink.json";
import { OINK_OINK_ADDRESS } from "config";
import { HookConstructorArgs } from "interfaces/hookConstructorArgs";

const BEFORE_SWAP_FLAG = BigInt(1) << BigInt(153);
const AFTER_SWAP_FLAG = BigInt(1) << BigInt(152);
const ACCESS_FLAG = BigInt(1) << BigInt(148);
const FLAG_MASK = BigInt("0xFFF") << BigInt(148);
const HOOKS_FLAGS = BEFORE_SWAP_FLAG | AFTER_SWAP_FLAG | ACCESS_FLAG;
const MAX_LOOP = 20000;

export const findHookAddress = async (
  constructorArgs: HookConstructorArgs
): Promise<Uint8Array> => {
  let hookAddress = "";
  const creationCodeWithArgs = concat([
    `0x${OinkOinkArtifact.bytecode.object}`,
    constructorArgs.poolManager,
    constructorArgs.oink,
    constructorArgs.creator,
    numberToHex(constructorArgs.creatorFeeBps),
  ]);

  for (let salt = 0; salt < MAX_LOOP; salt++) {
    hookAddress = getContractAddress({
      bytecode: creationCodeWithArgs,
      from: OINK_OINK_ADDRESS,
      opcode: "CREATE2",
      salt: toBytes(salt, { size: 32 }),
    });
    if ((BigInt(hookAddress) & FLAG_MASK) === HOOKS_FLAGS) {
      // TODO: In a real scenario, you should check if the code at the address is empty
      return toBytes(salt, { size: 32 });
    }
  }

  throw new Error("No suitable hook found. Please try again.");
};
