local M = {}

local defaults = {
  position = "top",
  border = "rounded",
  keymap = "<leader>tb",
  items = {
    { label = "Save", icon = "󰆓", command = "write" },
    { label = "Undo", icon = "󰕌", command = "undo" },
    { label = "Redo", icon = "󰑎", command = "redo" },
    { label = "Find", icon = "󰍉", keys = "/" },
    { label = "Quit", icon = "󰈆", command = "quit" },
  },
}

local state = { config = nil, win = nil, buf = nil, selected = 1 }

local function merged(opts)
  return vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

local function valid_items(items)
  for i, item in ipairs(items) do
    assert(type(item.label) == "string" and item.label ~= "", ("hanger: item %d needs a label"):format(i))
    assert(item.command or item.keys or item.action, ("hanger: item %d needs command, keys, or action"):format(i))
  end
end

local function close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win, state.buf = nil, nil
end

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  local chunks, starts, col = {}, {}, 0
  for i, item in ipairs(state.config.items) do
    local text = (" %s%s "):format(item.icon and (item.icon .. " ") or "", item.label)
    starts[i] = { col, col + #text }
    chunks[#chunks + 1], col = text, col + #text
    if i < #state.config.items then chunks[#chunks + 1], col = "│", col + 3 end
  end
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { table.concat(chunks) })
  vim.bo[state.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)
  for i, span in ipairs(starts) do
    vim.api.nvim_buf_add_highlight(state.buf, -1, i == state.selected and "PmenuSel" or "Pmenu", 0, span[1], span[2])
  end
  vim.api.nvim_win_set_cursor(state.win, { 1, starts[state.selected][1] })
end

local function select(delta)
  local count = #state.config.items
  state.selected = ((state.selected - 1 + delta) % count) + 1
  render()
end

local function activate()
  local item = state.config.items[state.selected]
  close()
  if item.action then
    vim.schedule(function() item.action(item) end)
  elseif item.keys then
    local keys = vim.api.nvim_replace_termcodes(item.keys, true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  else
    vim.schedule(function() vim.cmd(item.command) end)
  end
end

function M.open()
  close()
  local items = state.config.items
  if #items == 0 then return end
  state.selected = math.min(state.selected, #items)
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].filetype = "hanger"
  local labels = {}
  for i, item in ipairs(items) do
    labels[#labels + 1] = (" %s%s "):format(item.icon and (item.icon .. " ") or "", item.label)
    if i < #items then labels[#labels + 1] = "│" end
  end
  local width = vim.fn.strdisplaywidth(table.concat(labels))
  width = math.min(width, vim.o.columns - 2)
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor", row = state.config.position == "bottom" and (vim.o.lines - 4) or 1,
    col = math.max(0, math.floor((vim.o.columns - width) / 2)), width = width, height = 1,
    style = "minimal", border = state.config.border, title = " Hanger ", title_pos = "center",
  })
  vim.wo[state.win].cursorline = false
  local map = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = state.buf, silent = true, nowait = true }) end
  for _, key in ipairs({ "l", "<Right>", "<Tab>" }) do map(key, function() select(1) end) end
  for _, key in ipairs({ "h", "<Left>", "<S-Tab>" }) do map(key, function() select(-1) end) end
  map("<Home>", function() state.selected = 1; render() end)
  map("<End>", function() state.selected = #items; render() end)
  map("<CR>", activate); map("<Space>", activate)
  map("q", close); map("<Esc>", close)
  render()
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then close() else M.open() end
end

function M.setup(opts)
  state.config = merged(opts)
  valid_items(state.config.items)
  vim.api.nvim_create_user_command("Hanger", M.toggle, { desc = "Toggle the Hanger toolbar", force = true })
  if state.config.keymap then
    vim.keymap.set("n", state.config.keymap, M.toggle, { desc = "Toggle Hanger toolbar" })
  end
end

M._state = state
return M
