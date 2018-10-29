function [trigger_time] = wait_for_trigger()

    trigger = input('Waiting for trigger...','s');
    
    if strcmp(trigger,'t')
        trigger_time = datetime;
    else
        trigger_time = wait_for_trigger;
    end

    