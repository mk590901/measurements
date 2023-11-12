import device
import pubsub
import encoding.json as json

// export PATH=$HOME/toit_demo/:$PATH
// toit -d=nuc deploy measurements2.yaml
// toit device -d=nuc uninstall "Measurements"

INCOMING_TOPIC ::= "cloud:demo/ping"
OUTGOING_TOPIC ::= "cloud:demo/pong"

//////////////////////////////////////////////////
//  composeMessage
//////////////////////////////////////////////////
composeMessage id/string value/string -> string :
  mapJson := {"i" : id, "v" : value}
  jsonObj := json.encode mapJson
  jsonText := jsonObj.to_string
  return jsonText

//////////////////////////////////////////////////
//  generateValue
//////////////////////////////////////////////////
generateValue ident/string -> string :
  value := ""
  if (ident == "t1") :
    value = "$(90 + (random 30))"
  else :
    if (ident == "t2") :
      value = "$(70 + (random 20))"
    else :
      if (ident == "t3") :
        value = "$(90 + (random 10))"
      else :
        if (ident == "t4") : 
          value = "$(34 + (random 8))"
        else :
          if (ident == "t5") :
            value = "$(89 + (random 10))"
  return value;

time -> string :
  time := Time.now.local
  ms := time.ns / Duration.NANOSECONDS_PER_MILLISECOND
  precise_ms := "$(%02d time.h):$(%02d time.m):$(%02d time.s).$(%03d ms)"
  return precise_ms

interface IInvoke :
  invoke -> string

class Timer implements IInvoke :
  start_ := null
  ident_ := null
  type_  := null  //    periodic/pulse 
  delay_ := 0
  
  constructor _ident/string _type/string _delay/int :
    ident_ = _ident
    delay_ = _delay
    type_  = _type

  ident :
    return ident_

  delay :
    return delay_

  type :
    return type_

  start :
    start_ = Time.now.local.time

  reset :
    if (type_ == "periodic") :
      start_ = Time.now.local.time
    else :
      start_ = null
  
  invoke :
    return ident_ + "/" + "$(%03d delay_)" + "/" + type_

/// Runs the given $block periodically while the block returns true.
run_periodically duration [block] :
  duration.periodic :
    should_continue_running := block.call
    if not should_continue_running: return

run_periodically_in_task duration callback/Lambda:
  return task::
    run_periodically duration: callback.call

class TimersPool :
  interval_ms := 0
  task_       := null
  container_  := {:}

  constructor _interval_ms :
    interval_ms = _interval_ms

  createTimer _ident/string _type/string _delay/int -> bool : 
    timer := Timer _ident _type _delay
    if (container_.contains _ident) :
      return false
    container_[_ident] = timer
    return true

  deleteTimer _ident/string -> bool : 
    if (container_.contains _ident) :
      container_.remove _ident
      return true
    return false

  size -> int :
    return container_.size

  start :
    interval := Duration --ms=interval_ms
    task_ = run_periodically_in_task interval::
      container_.do : | ident |
        timer := container_[ident]
        if (timer.start_ != null) :
          if (timer.start_.to_now.in_ms >= timer.delay) :
            //message := "($time) [$(%03d timer.start_.to_now.in_ms)]:[$timer.invoke]"
            msg := composeMessage "$ident" (generateValue ident) //"$(random 1000)"
            pubsub.publish OUTGOING_TOPIC msg
            //print ("$message")
            timer.reset
      true  // Return value of the block.

  final :
    task_.cancel

  run ident/string :
    timer := container_[ident]
    if (timer != null) :
      timer.start

main :
    //print ("device->$device.hardware_id,name->$device.name")
  pubsub.subscribe INCOMING_TOPIC --auto_acknowledge: | msg/pubsub.Message |
    tp := TimersPool 50
    tp.start
    tp.createTimer "t1" "periodic" 250
    tp.createTimer "t2" "periodic" 300
    tp.createTimer "t3" "periodic" 400
    tp.createTimer "t4" "periodic" 420
    tp.createTimer "t5" "periodic" 350
    tp.run "t1"
    tp.run "t2"
    tp.run "t3"
    tp.run "t4"
    tp.run "t5"
    sleep (Duration --ms=30000)
    tp.final
    end := composeMessage "e" "end" //"$(random 1000)"
    pubsub.publish OUTGOING_TOPIC end
