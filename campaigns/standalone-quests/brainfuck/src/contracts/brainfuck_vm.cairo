import program

#[starknet::interface]
trait IBrainfuckVM<TContractState> {
    fn deploy(ref self: TContractState, program: Array<felt252>) -> u8;
    fn get_program(self: @TContractState, program_id: u8) -> Array<felt252>;
    fn call(self: @TContractState, program_id: u8, input: Array<u8>) -> Array<u8>;
}

#[starknet::contract]
mod BrainfuckVM {
    use starknet::storage::{Storage, StorageMap};

    #[storage]
    struct Storage {
        program_counter: u8,
        programs: StorageMap<u8, Array<felt252>>,
    }

    #[init]
    fn init() -> Storage {
        Storage {
            program_counter: 0,
            programs: StorageMap::new(),
        }
    }

    #[external]
    fn deploy(ref mut self: Storage, program: Array<felt252>) -> u8 {
        program.check();

        let program_id = self.program_counter;
        self.programs.insert(program_id, program);
        self.program_counter += 1;

        program_id
    }

    #[view]
    fn get_program(self: &Storage, program_id: u8) -> Array<felt252> {
        self.programs.get(program_id).unwrap()
    }

    #[external]
    fn call(self: &Storage, program_id: u8, input: Array<u8>) -> Array<u8> {
        let program = self.get_program(program_id);
        program.execute(program, &input)
    }
}