#pragma once

typedef unsigned long long size_t;

#ifdef __cplusplus
extern "C" {
#endif

#define HALCYON_RESULT_ERROR -1

#ifdef WIN32

#ifndef IMPORT_HALCYON_API
#define EXPORT_API __declspec(dllexport)
#else 
#define EXPORT_API __declspec(dllimport)
#endif

#else 

#define EXPORT_API 

#endif

typedef struct halc_nodes_t halc_nodes_t;
typedef struct halc_interactor_t halc_interactor_t;
typedef struct halc_strings_array_t halc_strings_array_t;

typedef struct HalcString {
    size_t len;
    const char* utf8;
} HalcString;

// fat pointer with info
typedef struct HalcStory {
    size_t num_nodes;
    halc_nodes_t* nodes;
}HalcStory;


// returns 0 on success
EXPORT_API int HalcStory_Parse(HalcString str, struct HalcStory* story);

EXPORT_API void HalcStory_Destroy(struct HalcStory* story);

// fat pointer with info
typedef struct HalcInteractor {
    size_t id;
    halc_interactor_t* interactor;
} HalcInteractor;

// returns 0 on success
EXPORT_API int HalcStory_CreateInteractorFromStart(
    struct HalcStory* story,
    HalcInteractor* interactor);

// returns 0 on success
EXPORT_API int HalcInteractor_GetStoryText(
    const HalcInteractor* interactor,
    HalcString* ostr);
    
EXPORT_API void HalcInteractor_GetSpeaker(
    const HalcInteractor* interactor,
    HalcString* ostr);
    
EXPORT_API void HalcInteractor_Destroy(
    const HalcInteractor* interactor);  

// returns the ID of the next node we traveled to. returns -1 if we got an error, and 0 if we reached the end of the story
EXPORT_API int HalcInteractor_Next(
    HalcInteractor* interactor);
    
typedef struct HalcChoicesList {
    size_t len;
    HalcString* strings;
    halc_strings_array_t* handle;
} HalcChoicesList;

EXPORT_API void HalcChoicesList_Destroy(
    HalcChoicesList* choices);

// returns the number of choices
EXPORT_API int HalcInteractor_GetChoices(
    HalcInteractor* interactor,
    HalcChoicesList* list);

// returns the ID of the next node we traveled to. returns -1 if we reached the end of the story.
EXPORT_API int HalcInteractor_SelectChoice(
    HalcInteractor* interactor,
    size_t choice);


#ifdef __cplusplus
}
#endif

