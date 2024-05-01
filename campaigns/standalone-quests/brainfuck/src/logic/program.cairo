use src::logic::utils::{
    iter, match_closing, match_opening, preprocess_and_add_chars
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
            match iter(ref len, ref str, ref strs) {
                Option::Some(char) => {
                    if char == '[' {
                        balance += 1;
                        continue;
                    }
                    if char == ']' {
                        assert(balance != 0, 'excess closing bracket');
                        balance -= 1;
                        continue;
                    }
                    if char
                        * (char - '+')
                        * (char - '>')
                        * (char - '<')
                        * (char - '-')
                        * (char - '.')
                        * (char - ',') != 0 {
                        panic_with_felt252('unrecognized character');
                    }
                },
                Option::None => {
                    assert(balance == 0, 'missing closing bracket');
                    break;
                }
            };
        };
    }

    fn execute(self: @Array<felt252>, input: Array<u8>) -> Array<u8> {
        let processedInstructions = preprocess_and_add_chars(self.span());
        let instructionCount = processedInstructions.len();
        let mut dataMemory: Felt252Dict<u8> = Default::default();
        let mut inputDataSpan = input.span();
        let mut outputData: Array<u8> = Default::default();
        let mut dataPointer: felt252 = 0;
        let mut programCounter: usize = 0;

        loop {
            match processedInstructions.get(programCounter) {
                Option::Some(instruction) => {
                    let currentInstruction = *instruction.unbox();
                    if currentInstruction == '>' {
                        if dataPointer == 255 {
                            dataPointer = 0
                        } else {
                            dataPointer += 1;
                        }
                    } else if currentInstruction == '<' {
                        if dataPointer == 0 {
                            dataPointer = 255
                        } else {
                            dataPointer -= 1;
                        }
                    } else if currentInstruction == '+' {
                        let currentValue = dataMemory.get(dataPointer);
                        dataMemory.insert(dataPointer, if currentValue == 255 {
                            0
                        } else {
                            currentValue + 1
                        });
                    } else if currentInstruction == '-' {
                        let currentValue = dataMemory.get(dataPointer);
                        dataMemory.insert(dataPointer, if currentValue == 0 {
                            255
                        } else {
                            currentValue - 1
                        });
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
                },
                Option::None => {
                    break;
                }
            }
            programCounter += 1;
        };
        outputData
    }
}