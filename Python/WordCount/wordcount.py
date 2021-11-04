# Software developed 100% by Stephen Merritt for an interview challenge
# This program reads a string of space-delimited words and outputs each unique word alphabetically along with how many
#  times the word appears in the string. For example "Red Red Blue" would return "('BLUE', 1), ('RED', 2)". The code does
#  not check for punctuation, so the input string "Red! Red" would return "('RED', 1), ('RED!', 1)".
def main():
    print("Hello, and welcome to Stephen Merritt's awesome solution!")
    print("Please input a string of words divided by spaces and be amazed by the returned list of words and counts!")
    wordcount_str = input()                        #Reads user input
    wordcount_str = wordcount_str.upper()          #Converts all words to upper case (Python is case-sensitive)
    wordcount_arr = sorted(wordcount_str.split())  #Splits string into array of words, default split is by whitespace

    print_list = []
    current_word = ''
    current_word_cnt = 0

    #Iterate through ordered list to find matching words
    for i in range(len(wordcount_arr)):
        if i == len(wordcount_arr) - 1:
            #Last word of array
            if wordcount_arr[i] == current_word or current_word_cnt == 0:
                #If the last word is a match or if the array is one word long, only need to print one line
                current_word_cnt = current_word_cnt + 1
            else:
                #If the last word doesn't match the previous word, need to print previous word before printing last word
                print_list.append((current_word, current_word_cnt))
                current_word_cnt = 1
            print_list.append((wordcount_arr[i], current_word_cnt))
        elif i == 0:
            #First word of array, set variables for word-matching
            current_word = wordcount_arr[0]
            current_word_cnt = 1
        elif wordcount_arr[i] == current_word:
            #Increment count if the words are the same
            current_word_cnt = current_word_cnt + 1
        else:
            #If the words are different, add the previous word to the print list and move on to the next word
            print_list.append((current_word, current_word_cnt))
            current_word = wordcount_arr[i]
            current_word_cnt = 1

    #Print items as a stacked list for readability
    print("Key: (WORD, COUNT)")
    for item in print_list:
        print(item)

# Default main
if __name__ == '__main__':
    main()
