use traits::{DivRem};

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

fn closed_brackets(ref counter: usize, instructions: @Array<u128>) {
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

fn opened_brackets(ref counter: usize, instructions: @Array<u128>) {
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