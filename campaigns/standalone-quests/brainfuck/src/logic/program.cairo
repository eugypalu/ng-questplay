use src::logic::utils::*;
use bytes_31::*;
use traits::*;

trait ProgramTrait {
    fn check(&self);
    fn execute(&self, input: Vec<u8>) -> Vec<u8>;
}

impl ProgramTrait for &[felt252] {
    fn check(&self) {
        let mut balance = 0;
        let mut len = 0;
        let mut str = 0;
        let strs = self;

        while let Some(char) = iter(&mut len, &mut str, &strs) {
            if char == '[' {
                balance += 1;
            } else if char == ']' {
                assert!(balance != 0, "excess closing bracket");
                balance -= 1;
            } else if char * (char - '+') * (char - '>') * (char - '<') * (char - '-') * (char - '.') * (char - ',') != 0 {
                panic!("unrecognized character");
            }
        }
        assert!(balance == 0, "missing closing bracket");
    }

    fn execute(&self, input: Vec<u8>) -> Vec<u8> {
        let processedInstructions = preprocess(self);
        let mut dataMemory: HashMap<felt252, u8> = HashMap::new();
        let mut inputData = input.into_iter();
        let mut outputData = Vec::new();
        let mut dataPointer = 0;
        let mut programCounter = 0;

        while programCounter < processedInstructions.len() {
            match processedInstructions[programCounter] {
                '>' => incr_ptr(&mut dataPointer),
                '<' => decr_ptr(&mut dataPointer),
                '+' => incr_mem(&mut dataMemory, dataPointer),
                '-' => decr_mem(&mut dataMemory, dataPointer),
                '.' => {
                    if let Some(&value) = dataMemory.get(&dataPointer) {
                        outputData.push(value);
                    }
                },
                ',' => {
                    if let Some(input_byte) = inputData.next() {
                        dataMemory.insert(dataPointer, input_byte);
                    }
                },
                '[' => {
                    if dataMemory.get(&dataPointer).copied().unwrap_or(0) == 0 {
                        match_closing(&mut programCounter, &processedInstructions);
                    }
                },
                ']' => {
                    if dataMemory.get(&dataPointer).copied().unwrap_or(0) != 0 {
                        match_opening(&mut programCounter, &processedInstructions);
                    }
                },
                _ => {},
            }
            programCounter += 1;
        }
        outputData
    }
}