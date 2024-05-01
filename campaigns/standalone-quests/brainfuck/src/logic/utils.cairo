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

fn preprocess_and_add_chars(mut programData: Span<felt252>) -> Array<u128> {
    if programData.len() == 0 {
        return Default::default();
    }
    let sequenceOption = programData.pop_back();
    let mut array = preprocess_and_add_chars(programData);

    let u256{low, high } = match sequenceOption {
        Option::Some(sequence) => {
            (*sequence).into()
        },
        Option::None => {
            return array;
        }
    };

    let mut sequenceLength = 15;
    if sequenceLength != 0 {
        let (sequence, character) = DivRem::div_rem(high, 256_u128.try_into().unwrap());
        sequenceLength -= 1;
        if character != 0 {
            array.append(character);
        }
    }

    let sequenceLength = 16;
    if sequenceLength != 0 {
        let (sequence, character) = DivRem::div_rem(low, 256_u128.try_into().unwrap());
        sequenceLength -= 1;
        if character != 0 {
            array.append(character);
        }
    }

    return array;
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