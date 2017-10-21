local lassert = require('luassert')
local Runner = require('feltest')
local run = Runner()
local calls = { }
local assertCalls
assertCalls = function(expected)
  return lassert.are.same(calls, expected)
end
run:describe('feltests', function(self)
  self:beforeEach(function(self)
    return table.insert(calls, "beforeEach inline #1")
  end)
  self:afterEach(function(self)
    return table.insert(calls, "afterEach inline #1")
  end)
  self:beforeEach(function(self)
    return table.insert(calls, "beforeEach inline #2")
  end)
  self:afterEach(function(self)
    return table.insert(calls, "afterEach inline #2")
  end)
  self:it("does a test, inline", function(self)
    assertCalls({
      "beforeEach inline #1",
      "beforeEach inline #2",
      "beforeEach appended #1",
      "beforeEach appended #2"
    })
    return table.insert(calls, "it inline #1")
  end)
  return self:it("does a second test, inline", function(self)
    assertCalls({
      "beforeEach inline #1",
      "beforeEach inline #2",
      "beforeEach appended #1",
      "beforeEach appended #2",
      "it inline #1",
      "afterEach inline #1",
      "afterEach inline #2",
      "afterEach appended #1",
      "afterEach appended #2",
      "beforeEach inline #1",
      "beforeEach inline #2",
      "beforeEach appended #1",
      "beforeEach appended #2"
    })
    return table.insert(calls, "it inline #2")
  end)
end):beforeEach(function(self)
  return table.insert(calls, "beforeEach appended #1")
end):afterEach(function(self)
  return table.insert(calls, "afterEach appended #1")
end):beforeEach(function(self)
  return table.insert(calls, "beforeEach appended #2")
end):afterEach(function(self)
  return table.insert(calls, "afterEach appended #2")
end):it("does a test, appended", function(self)
  assertCalls({
    "beforeEach inline #1",
    "beforeEach inline #2",
    "beforeEach appended #1",
    "beforeEach appended #2",
    "it inline #1",
    "afterEach inline #1",
    "afterEach inline #2",
    "afterEach appended #1",
    "afterEach appended #2",
    "beforeEach inline #1",
    "beforeEach inline #2",
    "beforeEach appended #1",
    "beforeEach appended #2",
    "it inline #2",
    "afterEach inline #1",
    "afterEach inline #2",
    "afterEach appended #1",
    "afterEach appended #2",
    "beforeEach inline #1",
    "beforeEach inline #2",
    "beforeEach appended #1",
    "beforeEach appended #2"
  })
  return table.insert(calls, "it appended #1")
end):it('does a second test, appended', function(self)
  return assertCalls({
    "beforeEach inline #1",
    "beforeEach inline #2",
    "beforeEach appended #1",
    "beforeEach appended #2",
    "it inline #1",
    "afterEach inline #1",
    "afterEach inline #2",
    "afterEach appended #1",
    "afterEach appended #2",
    "beforeEach inline #1",
    "beforeEach inline #2",
    "beforeEach appended #1",
    "beforeEach appended #2",
    "it inline #2",
    "afterEach inline #1",
    "afterEach inline #2",
    "afterEach appended #1",
    "afterEach appended #2",
    "beforeEach inline #1",
    "beforeEach inline #2",
    "beforeEach appended #1",
    "beforeEach appended #2",
    "it appended #1",
    "afterEach inline #1",
    "afterEach inline #2",
    "afterEach appended #1",
    "afterEach appended #2",
    "beforeEach inline #1",
    "beforeEach inline #2",
    "beforeEach appended #1",
    "beforeEach appended #2"
  })
end)
run:describe("nested tests", function(self)
  self:beforeEach(function(self)
    self.before_ran_lvl1 = true
  end)
  self:describe("second level", function(self)
    self:beforeEach(function(self)
      self.before_ran_lvl2 = true
    end)
    return self:it("has run a test", function(self)
      lassert.is_true(self.before_ran_lvl1)
      return lassert.is_true(self.before_ran_lvl2)
    end)
  end)
  return self:it("has run a test", function(self)
    lassert.is_true(self.before_ran_lvl1)
    return lassert.is_nil(self.before_ran_lvl2)
  end)
end)
local before_ran = 0
local after_ran = 0
local it_ran = 0
run:describe("async tests", function(self)
  self:beforeEach(function(self)
    coroutine.yield()
    before_ran = before_ran + 1
  end)
  self:afterEach(function(self)
    coroutine.yield()
    after_ran = after_ran + 1
  end)
  self:it("runs a test async", function(self)
    coroutine.yield()
    it_ran = it_ran + 1
  end)
  return self:it("has run a test async", function(self)
    lassert.are.equal(before_ran, 2)
    lassert.are.equal(after_ran, 1)
    return lassert.are.equal(it_ran, 1)
  end)
end)
local high_prio = 0
local low_prio = 0
local success = run:runTests()
if high_prio == 0 then
  lassert.is_nil(success)
end
local resume_count = 0
while success == nil do
  resume_count = resume_count + 1
  success = run:resumeTests()
end
if high_prio == 0 then
  lassert.is.same(resume_count, 5)
end
print("Tests completed with success=" .. tostring(success))
return os.exit(sucess and 0 or 1)
