use traits::{TryInto, DivRem};
use bytes_31::{
    split_bytes31, bytes31_try_from_felt252, BYTES_IN_U128, POW_2_8, one_shift_left_bytes_u128,
    BYTES_IN_BYTES31
};

fn iter(ref length: usize, ref sequence: felt252, ref nextSequences: Span<felt252>) -> Option<felt252> {
    if length == 0 {
        match nextSequences.pop_front() {
            Option::Some(newSequence) => {
                length = 31;
                sequence = *newSequence;
            },
            Option::None => {
                return Option::None;
            },
        };
    };
    let newLength = length - 1;
    let (newSequence, character) = split_bytes31(sequence, length, newLength);
    length = newLength;
    sequence = newSequence;
    Option::Some(character)
}

fn preprocess(mut programData: Span<felt252>) -> Array<u128> {
    if programData.len() == 0 {
        return Default::default();
    }
    let sequenceOption = programData.pop_back();
    let mut array = preprocess(programData);

    let u256{low, high } = match sequenceOption {
        Option::Some(sequence) => {
            (*sequence).into()
        },
        Option::None => {
            return array;
        }
    };
    rec_add_chars(ref array, 15, high);
    rec_add_chars(ref array, 16, low);
    return array;
}

fn rec_add_chars(ref array: Array<u128>, sequenceLength: felt252, sequence: u128) {
    if sequenceLength == 0 {
        return;
    }
    let (sequence, character) = DivRem::div_rem(sequence, 256_u128.try_into().unwrap());
    rec_add_chars(ref array, sequenceLength - 1, sequence);
    if character != 0 {
        array.append(character);
    }
}

fn incr_ptr(ref pointer: felt252) {
    if pointer == 255 {
        pointer = 0
    } else {
        pointer += 1;
    }
}

fn decr_ptr(ref pointer: felt252) {
    if pointer == 0 {
        pointer = 255
    } else {
        pointer -= 1;
    }
}

fn incr_mem(ref memory: Felt252Dict<u8>, pointer: felt252) {
    let currentValue = memory.get(pointer);
    memory.insert(pointer, if currentValue == 255 {
        0
    } else {
        currentValue + 1
    });
}

fn decr_mem(ref memory: Felt252Dict<u8>, pointer: felt252) {
    let currentValue = memory.get(pointer);
    memory.insert(pointer, if currentValue == 0 {
        255
    } else {
        currentValue - 1
    });
}

fn match_closing(ref counter: usize, instructions: @Array<u128>) {
    let mut balance = 0;
    loop {
        counter += 1;
        let instruction = *instructions.at(counter);
        if instruction == ']' {
            if balance == 0 {
                break;
            };
            balance -= 1;
        } else if instruction == '[' {
            balance += 1;
        };
    };
}

fn match_opening(ref counter: usize, instructions: @Array<u128>) {
    let mut balance = 0;
    loop {
        counter -= 1;
        let instruction = *instructions.at(counter);
        if instruction == '[' {
            if balance == 0 {
                break;
            };
            balance -= 1;
        } else if instruction == ']' {
            balance += 1;
        };
    };
}