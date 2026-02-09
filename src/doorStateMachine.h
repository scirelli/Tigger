#ifndef _DOORSTATEMACHINE_H
#define _DOORSTATEMACHINE_H
#include <stdbool.h>
#include <stddef.h>
#include "Arduino.h"
#include "cck_types.h"
#include "states.h"

#ifdef __cplusplus
extern "C"
{
#endif

#define STATE_PAUSE                -1
#define STATE_ERROR                 0
#define STATE_PRE_IDLE              1
#define STATE_IDLE                  2
#define STATE_PRE_NEW_FILE          3
#define STATE_NEW_FILE              4
#define STATE_PRE_READ_SENSORS      5
#define STATE_READ_SENSORS          6
#define STATE_TEST                  9

#define STATE_ERROR_NONE 20
#define STATE_ERROR_TEST 21

typedef void (*door_event_handler_t)(cck_time_t);

//typedef void (*door_event_handler_fnc_t)(cck_time_t);
//typedef struct {
//   door_event_handler_fnc_t,
//   void *params;
//} door_event_handler_t;

typedef enum:state_id_t {
    PRE_IDLE = 0,
    IDLE,
    PRE_NEW_FILE,
    NEW_FILE,
    PRE_READ_SENSORS,
    READ_SENSORS,
    _DOOR_STATE_COUNT
} door_states_id_t;

typedef enum: state_event_id_t  {
    DOOR_EVENT_BUTTON_1_PRESS = 0,
    _DOOR_EVENT_COUNT
} door_events_t;

typedef struct {
    state_t state;
    door_event_handler_t event_handlers[_DOOR_EVENT_COUNT];
} door_state_t;

bool setup_door_state_machine(state_machine_t *);
bool door_set_event_handle(door_states_id_t, door_events_t, door_event_handler_t);


static void door_state_event_handler(state_t* state_ptr, state_event_id_t evt, cck_time_t t);
static bool is_valid_door_state_id(door_states_id_t);
static bool is_valid_door_event_id(door_events_t);

#ifdef __cplusplus
}
#endif //__cplusplus
#endif //_DOORSTATEMACHINE_H
