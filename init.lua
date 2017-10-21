local Runner = nil
local Describe
do
  local _class_0
  local _base_0 = {
    describe = function(self, subject, fn)
      local desc = Describe(self._runner, self._subject .. " " .. subject, fn, (function()
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self._beforeFns
        for _index_0 = 1, #_list_0 do
          local f = _list_0[_index_0]
          _accum_0[_len_0] = f
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), (function()
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self._afterFns
        for _index_0 = 1, #_list_0 do
          local f = _list_0[_index_0]
          _accum_0[_len_0] = f
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
      return desc
    end,
    beforeEach = function(self, fn)
      table.insert(self._beforeFns, fn)
      return self
    end,
    afterEach = function(self, fn)
      table.insert(self._afterFns, fn)
      self._afterFn = fn
      return self
    end,
    it = function(self, description, fn)
      table.insert(self._behaviours, {
        description = self._subject .. ' ' .. description,
        testFn = coroutine.create(fn)
      })
      return self
    end,
    fit = function(self, description, fn)
      self._runner.priority_mode = true
      table.insert(self._priority_behaviours, {
        description = self._subject .. ' ' .. description,
        testFn = coroutine.create(fn)
      })
      return self
    end,
    _runTests = function(self)
      return coroutine.create(function()
        if self._runner.priority_mode then
          self._behaviours = self._priority_behaviours
        end
        local _list_0 = self._behaviours
        for _index_0 = 1, #_list_0 do
          local behaviour = _list_0[_index_0]
          local verify = self:_verifyBehaviour(behaviour)
          while true do
            local success, message = coroutine.resume(verify)
            if not success then
              error("\n" .. message)
            elseif coroutine.status(verify) == "suspended" then
              coroutine.yield()
            else
              break
            end
          end
        end
      end)
    end,
    _verifyBehaviour = function(self, behaviour)
      return coroutine.create(function()
        local start = os.time()
        self._runner.curr_test_num = self._runner.curr_test_num + 1
        io.write("[" .. self._runner.curr_test_num .. "] " .. behaviour.description .. " ...\n")
        local beforeFns
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self._beforeFns
          for _index_0 = 1, #_list_0 do
            local fn = _list_0[_index_0]
            _accum_0[_len_0] = coroutine.create(fn)
            _len_0 = _len_0 + 1
          end
          beforeFns = _accum_0
        end
        local afterFns
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self._afterFns
          for _index_0 = 1, #_list_0 do
            local fn = _list_0[_index_0]
            _accum_0[_len_0] = coroutine.create(fn)
            _len_0 = _len_0 + 1
          end
          afterFns = _accum_0
        end
        for _index_0 = 1, #beforeFns do
          local beforeFn = beforeFns[_index_0]
          start = os.time()
          while true do
            local is_ok, err = coroutine.resume(beforeFn, behaviour)
            if not is_ok then
              error("\n" .. err)
            elseif coroutine.status(beforeFn) ~= "suspended" then
              break
            elseif os.time() - start > Runner.TIMEOUT then
              error("timeout after " .. tostring(Runner.TIMEOUT) .. "s")
            else
              coroutine.yield()
            end
          end
        end
        start = os.time()
        local success = false
        local message = nil
        while true do
          success, message = coroutine.resume(behaviour.testFn, behaviour)
          if not success then
            break
          elseif coroutine.status(behaviour.testFn) ~= "suspended" then
            break
          elseif os.time() - start > Runner.TIMEOUT then
            success = false
            message = "timeout after " .. tostring(Runner.TIMEOUT) .. "s"
            break
          else
            coroutine.yield()
          end
        end
        for _index_0 = 1, #afterFns do
          local afterFn = afterFns[_index_0]
          start = os.time()
          while true do
            local is_ok, err = coroutine.resume(afterFn, behaviour)
            if not is_ok then
              error("\n" .. err)
            elseif coroutine.status(afterFn) ~= "suspended" then
              break
            elseif os.time() - start > Runner.TIMEOUT then
              error("timeout after .. " .. tostring(Runner.TIMEOUT) .. "s\n")
            else
              coroutine.yield()
            end
          end
        end
        if success then
          io.write("... PASSED\n\n")
        else
          io.write("... FAILED\n" .. message .. "\n\n")
        end
        self._runner.success = self._runner.success and success
      end)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, runner, subject, fn, beforeFns, afterFns)
      if beforeFns == nil then
        beforeFns = { }
      end
      if afterFns == nil then
        afterFns = { }
      end
      self._runner = runner
      self._subject = subject
      self._priority_behaviours = { }
      self._behaviours = { }
      self._beforeFns = beforeFns
      self._afterFns = afterFns
      table.insert(self._runner.descriptions, self)
      if fn then
        return fn(self)
      end
    end,
    __base = _base_0,
    __name = "Describe"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Describe = _class_0
end
do
  local _class_0
  local _base_0 = {
    describe = function(self, subject, fn)
      return Describe(self, subject, fn)
    end,
    runTests = function(self)
      for _, description in ipairs(self.descriptions) do
        self.num_tests = self.num_tests + #description._behaviours
      end
      io.write("Running " .. self.num_tests .. " tests\n")
      return self:resumeTests()
    end,
    resumeTests = function(self)
      if coroutine.status(self._asyncRunTests) == "dead" then
        return self.success
      end
      local success, message = coroutine.resume(self._asyncRunTests)
      if not success then
        io.write(message .. "\n")
        self.success = false
      end
      if coroutine.status(self._asyncRunTests) == "suspended" then
        return nil
      end
      return self.success
    end,
    _createAsyncTestsRunner = function(self)
      return coroutine.create(function()
        for _, description in ipairs(self.descriptions) do
          local describeRunner = description:_runTests()
          while true do
            local success, message = coroutine.resume(describeRunner, description)
            if not success then
              error("\n" .. message)
            elseif coroutine.status(describeRunner) == "suspended" then
              coroutine.yield()
            else
              break
            end
          end
        end
      end)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.num_tests = 0
      self.curr_test_num = 0
      self.success = true
      self.descriptions = { }
      self.priority_mode = false
      self._asyncRunTests = self:_createAsyncTestsRunner()
    end,
    __base = _base_0,
    __name = "Runner"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.TIMEOUT = 5
  Runner = _class_0
end
return Runner
