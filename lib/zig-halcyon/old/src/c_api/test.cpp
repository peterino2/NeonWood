#include "Halcyon.h"
#include <stdio.h>
#include <iostream>
#include <wInDOWs.h>

int main(int argc, char** argv)
{    // Set console code page to UTF-8 so console known how to interpret string data
    SetConsoleOutputCP(CP_UTF8);

    // Enable buffering to prevent VS from chopping up UTF-8 byte sequences
    setvbuf(stdout, nullptr, _IOFBF, 1000);
    std::cout << "hello world" << std::endl;

    HalcStory story;
 		const char str[] = 
			 "[hello]\n"
			 "Dude: Hey man how's it going?\n"
			 "$: You notice that the nice man is talking to you\n"
			 "    > Praise him: \n"
			 "        Dude: Damn dude thanks so much for your compliment\n"
			 "    > Call him something bad: \n"
			 "        Dude: Wow you really hurt my feelings\n"
			 "    > Can we start over?: \n"
			 "        Dude: Of course! I'll take this convo back to the start\n"
			 "        @goto hello\n"
			 "$: End of the story";

    HalcStory_Parse(
            HalcString{
            sizeof(str)/sizeof(str[0]),
            &str[0]
        },
        &story
    );

    std::cout << "story node count : " << story.num_nodes << std::endl;

    HalcInteractor i;

    HalcStory_CreateInteractorFromStart(&story, &i);


    HalcString ostr;
    HalcInteractor_GetStoryText(&i, &ostr);
    
    if(ostr.utf8[ostr.len-1] != '\0') 
        std::cout << "We got a huge issue here, null terminator is missing " << std::endl;

    HalcInteractor_Next(&i);
    
    std::cout << "story node 1: " << ostr.utf8 << std::endl;

    HalcString ostr2;
    HalcInteractor_GetStoryText(&i, &ostr2);
    std::cout << "story node 2: " << ostr2.utf8 << std::endl;
    
    {
        HalcChoicesList choicesList;

        int result = HalcInteractor_GetChoices(&i, &choicesList);

        printf("addr of choicesList: 0x%x\n", choicesList.handle);

        std::cout << "got choices (count = " << choicesList.len << ")" << std::endl;

        for(int i = 0; i < choicesList.len; i++)
        {
            auto str = choicesList.strings[i];
            std::cout << "  - " << str.utf8 << " (len = " << str.len << ")" << std::endl;
        }
        if(result != -1)
        {
            HalcChoicesList_Destroy(&choicesList);
        }
    }

    HalcInteractor_SelectChoice(&i, 2);

    HalcString ostr3;
    HalcString speaker;
    HalcInteractor_GetStoryText(&i, &ostr3);
    std::cout << "story node afterChoice: "<< i.id <<"> " << ostr3.utf8 << std::endl;

    HalcInteractor_Next(&i);
    HalcInteractor_GetStoryText(&i, &ostr3);
    HalcInteractor_GetSpeaker(&i, &speaker);
    std::cout << "story node after afterchoice: " << i.id <<"> " << speaker.utf8 << ": " << ostr3.utf8 << std::endl;

    HalcInteractor_Next(&i);
    HalcInteractor_GetStoryText(&i, &ostr3);
    HalcInteractor_GetSpeaker(&i, &speaker);
    std::cout << i.id <<"> " << speaker.utf8 << ": " << ostr3.utf8 << std::endl;

    HalcInteractor_Next(&i);
    HalcInteractor_GetStoryText(&i, &ostr3);
    HalcInteractor_GetSpeaker(&i, &speaker);
    std::cout << i.id <<"> " << speaker.utf8 << ": " << ostr3.utf8 << std::endl;

    HalcStory_Destroy(&story);
}

