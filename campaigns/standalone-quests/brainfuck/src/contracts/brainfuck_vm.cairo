#[starknet::interface]
trait IBrainfuckVM<TContractState> {
    fn deploy(ref self: TContractState, program: Array<felt252>) -> u8;
    fn get_program(self: @TContractState, program_id: u8) -> Array<felt252>;
    fn call(self: @TContractState, program_id: u8, input: Array<u8>) -> Array<u8>;
}

#[starknet::contract]
mod BrainfuckVM {
    #[storage]
    struct Storage {
        programs: Felt252Dict<Array<felt252>>,  # Dictionary mapping program IDs to programs.
    }

    impl IBrainfuckVM<Storage> of IBrainfuckVM {
        fn deploy(ref self: Storage, program: Array<felt252>) -> u8 {
            # Validate the program.
            program.check()

            # Get a new ID.
            let program_id = self.programs.len()

            # Store the program.
            self.programs[program_id] = program

            # Return the ID.
            return program_id
        }

        fn get_program(self: @Storage, program_id: u8) -> Array<felt252> {
            return self.programs[program_id]
        }

        fn call(self: @Storage, program_id: u8, input: Array<u8>) -> Array<u8> {
            let program = self.programs[program_id]
            return program.execute(input)
        }
    }
}
