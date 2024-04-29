use src::logic::utils::{
    iter, incr_ptr, decr_ptr, incr_mem, decr_mem, match_closing, match_opening, preprocess
};
use bytes_31::{
    split_bytes31, bytes31_try_from_felt252, BYTES_IN_U128, POW_2_8, one_shift_left_bytes_u128,
    BYTES_IN_BYTES31
};
use traits::{Into, DivRem};

trait ProgramTrait {
    fn check(self: @Array<felt252>);
    fn execute(self: @Array<felt252>, input: Array<u8>) -> Array<u8>;
}

impl ProgramTraitImpl of ProgramTrait {
    fn check(self: @Array<felt252>) {
        let mut balance: felt252 = 0;
        let (mut len, mut str, mut strs) = (0, 0, self.span());

        loop {
            let maybe_char = iter(ref len, ref str, ref strs);
            if maybe_char == Option::None {
                assert(balance == 0, 'missing closing bracket');
                break;
            }
            let char = *maybe_char.unbox();
            if char == '[' {
                balance += 1;
            } else if char == ']' {
                assert(balance != 0, 'excess closing bracket');
                balance -= 1;
            } else if char
                * (char - '+')
                * (char - '>')
                * (char - '<')
                * (char - '-')
                * (char - '.')
                * (char - ',') != 0 {
                panic_with_felt252('unrecognized character');
            }
        };
    }

    fn execute(self: @Array<felt252>, input: Array<u8>) -> Array<u8> {
        let processedInstructions = preprocess(self.span());
        let instructionCount = processedInstructions.len();
        let mut dataMemory: Felt252Dict<u8> = Default::default();
        let mut inputDataSpan = input.span();
        let mut outputData: Array<u8> = Default::default();
        let mut dataPointer: felt252 = 0;
        let mut programCounter: usize = 0;

        loop {
            let maybe_instruction = processedInstructions.get(programCounter);
            if maybe_instruction == Option::None {
                break;
            }
            let currentInstruction = *maybe_instruction.unwrap().unbox();
            if currentInstruction == '>' {
                incr_ptr(ref dataPointer);
            } else if currentInstruction == '<' {
                decr_ptr(ref dataPointer);
            } else if currentInstruction == '+' {
                incr_mem(ref dataMemory, dataPointer);
            } else if currentInstruction == '-' {
                decr_mem(ref dataMemory, dataPointer);
            } else if currentInstruction == '.' {
                outputData.append(dataMemory.get(dataPointer));
            } else if currentInstruction == ',' {
                dataMemory.insert(dataPointer, *inputDataSpan.pop_front().unwrap());
            } else if currentInstruction == '[' {
                if dataMemory.get(dataPointer) == 0 {
                    match_closing(ref programCounter, @processedInstructions);
                };
            } else if currentInstruction == ']' {
                if dataMemory.get(dataPointer) != 0 {
                    match_opening(ref programCounter, @processedInstructions);
                };
            };
            programCounter += 1;
        };
        outputData
    }
}