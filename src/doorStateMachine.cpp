#include "doorStateMachine.h"

static door_state_t door_states[_DOOR_STATE_COUNT] = {
    [PRE_IDLE] = {
        .state = {
            .state_id = PRE_IDLE,
            .evtHandler = door_state_event_handler,
            .next_state = (state_t*)&door_states[IDLE]
        }
    },
    [IDLE] = {
        .state = {
            .state_id = IDLE,
            .evtHandler = door_state_event_handler,
            .next_state = NULL
        }
    }
};

bool setup_door_state_machine(state_machine_t *sm_ptr)
{
    if(!sm_ptr) return false;
    return state_init_machine(sm_ptr, &door_states[IDLE].state);
}

bool door_set_event_handle(door_states_id_t state_id, door_events_t evt_id, door_event_handler_t fnc)
{
    if(!is_valid_door_state_id(state_id)) return false;
    if(!is_valid_door_event_id(evt_id)) return false;

    door_state_t *state_ptr = &door_states[state_id];
    state_ptr->event_handlers[evt_id] = fnc;

    return true;
}

static bool is_valid_door_state_id(door_states_id_t state_id)
{
    return (state_id >= 0 && state_id < _DOOR_STATE_COUNT);
}

static bool is_valid_door_event_id(door_events_t evt_id)
{
    return (evt_id >= 0 && evt_id < _DOOR_EVENT_COUNT);
}

static void door_state_event_handler(state_t* state_ptr, state_event_id_t evt_id, cck_time_t t)
{
    if(!state_ptr) return;
    if(!is_valid_door_event_id((door_events_t)evt_id)) return;
    door_state_t* self = (door_state_t*)state_ptr;

    if(self->event_handlers[evt_id]) {
        self->event_handlers[evt_id](t);
    }
}


//===================================================================
// Pre Idle State
//==================================================================
//===================================================================



//===================================================================
// Idle State
//==================================================================
//===================================================================
