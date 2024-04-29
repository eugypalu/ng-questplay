# Import necessary modules
from starkware.cairo.common.dict import Dict

# Define an interface for the contract
#[starknet::interface]
trait IBrainfuckVM {
    fn deploy(ref self: Storage, program: Array<felt252>) -> u8;
    fn get_program(self: @Storage, program_id: u8) -> Array<felt252>;
    fn call(self: @Storage, program_id: u8, input: Array<u8>) -> Array<u8>;
}

#[starknet::contract]
mod BrainfuckVM {
    # Define storage to store programs
    #[storage]
    struct Storage {
        programs: Dict<u8, Array<felt252>>  # Dictionary mapping IDs to programs
    }

    impl IBrainfuckVM for Storage {
        # Deploy function
        fn deploy(ref self: Storage, program: Array<felt252>) -> u8 {
            # Check program validity
            program.check()

            # Get a new program ID
            let program_id = self.programs.len()

            # Store the program
            self.programs[program_id] = program

            return program_id
        }

        # Get program function
        fn get_program(self: @Storage, program_id: u8) -> Array<felt252> {
            return self.programs[program_id]
        }

        # Call function
        fn call(self: @Storage, program_id: u8, input: Array<u8>) -> Array<u8> {
            # Retrieve the program
            let program = self.programs[program_id]

            # Execute the program and return output
            return program.execute(input)
        }
    }
}
