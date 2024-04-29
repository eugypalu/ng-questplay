# Import necessary modules
from starkware.cairo.common.dict import Dict
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc_dict

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
            # Validate the program
            program.check()

            # Get a new program ID
            let program_id: u8 = self.programs.len()

            # Store the program
            self.programs.insert(program_id, program)

            # Return the ID
            return program_id
        }

        # Get program function
        fn get_program(self: @Storage, program_id: u8) -> Array<felt252> {
            return self.programs.get(program_id).unwrap()
        }

        # Call function
        fn call(self: @Storage, program_id: u8, input: Array<u8>) -> Array<u8> {
            # Retrieve the program
            let program = self.programs.get(program_id).unwrap()

            # Execute the program and return output
            return program.execute(input)
        }
    }
}
