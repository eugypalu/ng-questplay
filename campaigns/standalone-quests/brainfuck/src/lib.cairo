mod logic {
    mod program;
    mod utils;
}

#[starknet::interface]
trait IBrainfuckVM<TContractState> {
    fn deploy(ref self: TContractState, programData: Array<felt252>) -> u128;
    fn get_program(self: @TContractState, programId: u128) -> Array<felt252>;
    fn call(self: @TContractState, programId: u128, inputData: Array<u8>) -> Array<u8>;
    fn check(self: @TContractState, programId: u128, inputData: Array<u8>);
}

#[starknet::contract]
mod BrainfuckVM {
    use core::array::ArrayTrait;
    use super::IBrainfuckVM;

    use brainfuck::logic::program::{ProgramTrait, ProgramTraitImpl};

    #[external(v0)]
    impl BrainfuckVMImpl of super::IBrainfuckVM<ContractState> {
        fn deploy(ref self: ContractState, mut programData: Array<felt252>) -> u128 {
            match programData.pop_front() {
                Option::Some(programPart) => {
                    let partId = programData.len();
                    let programId = self.deploy(programData);
                    self.prog.write((programId, partId), programPart);
                    programId
                },
                Option::None => {
                    let programId = self.prog_len.read();
                    self.prog_len.write(programId + 1);
                    programId
                }
            }
        }

        fn get_program(self: @ContractState, programId: u128) -> Array<felt252> {
            self.read_program(programId, 0)
        }

        fn call(self: @ContractState, programId: u128, inputData: Array<u8>) -> Array<u8> {
            self.read_program(programId, 0).execute(inputData)
        }

        fn check(self: @ContractState, programId: u128, inputData: Array<u8>) {
            self.read_program(programId, 0).check()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn read_program(self: @ContractState, programId: u128, index: usize) -> Array<felt252> {
            let programPart = self.prog.read((programId, index));
            if programPart == 0 {
                Default::default()
            } else {
                let mut programData = self.read_program(programId, index + 1);
                programData.append(programPart);
                programData
            }
        }
    }

    #[storage]
    struct Storage {
        prog_len: u128,
        prog: LegacyMap<(u128, usize), felt252>,
    }
}