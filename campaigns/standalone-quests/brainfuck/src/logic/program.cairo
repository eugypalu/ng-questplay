from src.logic.utils import iter, incr_ptr, decr_ptr, incr_mem, decr_mem, match_closing, match_opening, preprocess
from bytes_31 import split_bytes31, bytes31_try_from_felt252, BYTES_IN_U128, POW_2_8, one_shift_left_bytes_u128, BYTES_IN_BYTES31
from traits import Into, DivRem

struct ProgramTrait:
    member check: func(self: ProgramTrait*, self_content: felt*)
    member execute: func(self: ProgramTrait*, self_content: felt*, input: felt*) -> (output: felt*)

func ProgramTrait__check(self: ProgramTrait*, self_content: felt*):
    let balance = 0
    let len = 0
    let str = 0
    let strs = self_content

    loop:
        let maybe_char = iter(len, str, strs)
        if maybe_char == 0:
            assert balance == 0
            return ()
        end

        let char = maybe_char
        if char == '[':
            balance += 1
        elif char == ']':
            assert balance != 0
            balance -= 1
        elif char * (char - '+') * (char - '>') * (char - '<') * (char - '-') * (char - '.') * (char - ',') != 0:
            panic()
        end
    end

func ProgramTrait__execute(self: ProgramTrait*, self_content: felt*, input: felt*) -> (output: felt*):
    let processedInstructions = preprocess(self_content)
    let instructionCount = len(processedInstructions)
    let dataMemory: DictAccess* = alloc()
    let inputDataSpan = input
    let outputData: felt* = alloc()
    let dataPointer = 0
    let programCounter = 0

    loop:
        let maybe_instruction = processedInstructions[programCounter]
        if maybe_instruction == 0:
            return (outputData)
        end

        let currentInstruction = maybe_instruction
        if currentInstruction == '>':
            incr_ptr(dataPointer)
        elif currentInstruction == '<':
            decr_ptr(dataPointer)
        elif currentInstruction == '+':
            incr_mem(dataMemory, dataPointer)
        elif currentInstruction == '-':
            decr_mem(dataMemory, dataPointer)
        elif currentInstruction == '.':
            outputData = dataMemory[dataPointer]
        elif currentInstruction == ',':
            dataMemory[dataPointer] = inputDataSpan[0]
            inputDataSpan += 1
        elif currentInstruction == '[':
            if dataMemory[dataPointer] == 0:
                match_closing(programCounter, processedInstructions)
            end
        elif currentInstruction == ']':
            if dataMemory[dataPointer] != 0:
                match_opening(programCounter, processedInstructions)
            end
        end

        programCounter += 1
    end
end