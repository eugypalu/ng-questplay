#[starknet::interface]
trait IBrainfuckVM<TContractState> {
    fn deploy(&self, state: &TContractState, program_data: Vec<felt252>) -> u128;
    fn get_program(&self, state: &TContractState, program_id: u128) -> Vec<felt252>;
    fn call(&self, state: &TContractState, program_id: u128, input_data: Vec<u8>) -> Vec<u8>;
}

#[starknet::contract]
mod BrainfuckVM {
    use core::array::ArrayTrait;
    use super::IBrainfuckVM;
    use src::logic::program::{ProgramTrait, ProgramTraitImpl};
    use std::collections::HashMap;

    #[storage]
    struct Storage {
        prog_len: u128,
        prog: HashMap<(u128, usize), felt252>,
    }

    impl InternalTrait for ContractState {
        fn read_program(&self, program_id: u128, index: usize) -> Vec<felt252> {
            let program_part = self.prog.get(&(program_id, index)).cloned().unwrap_or(0);
            if program_part == 0 {
                Vec::new()
            } else {
                let mut program_data = self.read_program(program_id, index + 1);
                program_data.push(program_part);
                program_data
            }
        }
    }

    impl IBrainfuckVM<ContractState> for ContractState {
        fn deploy(&self, mut program_data: Vec<felt252>) -> u128 {
            if let Some(program_part) = program_data.pop() {
                let part_id = program_data.len();
                let program_id = self.deploy(program_data);
                self.prog.insert((program_id, part_id), program_part);
                return program_id;
            } else {
                let program_id = self.prog_len;
                self.prog_len += 1;
                return program_id;
            }
        }

        fn get_program(&self, program_id: u128) -> Vec<felt252> {
            self.read_program(program_id, 0)
        }

        fn call(&self, program_id: u128, input_data: Vec<u8>) -> Vec<u8> {
            self.read_program(program_id, 0).execute(input_data)
        }
    }
}
