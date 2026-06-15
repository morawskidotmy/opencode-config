#!/usr/bin/env node
import fs from "node:fs"
import path from "node:path"

const target = process.argv[2] || path.join(process.env.HOME || "", ".config/opencode/opencode.jsonc")
const args = process.argv.slice(3)
const tuneConfig = args.includes("--tune-config")
const codingAgentIndex = args.indexOf("--coding-agent-personality")
const codingAgentInstructionPath = codingAgentIndex >= 0 ? args[codingAgentIndex + 1] : ""
const removeInstructionIndex = args.indexOf("--remove-instruction")
const removeInstructionPath = removeInstructionIndex >= 0 ? args[removeInstructionIndex + 1] : ""

function stripJsonc(input) {
  let out = ""
  let inString = false
  let quote = ""
  let escaped = false
  let lineComment = false
  let blockComment = false

  for (let i = 0; i < input.length; i += 1) {
    const c = input[i]
    const n = input[i + 1]

    if (lineComment) {
      if (c === "\n") {
        lineComment = false
        out += c
      }
      continue
    }
    if (blockComment) {
      if (c === "*" && n === "/") {
        blockComment = false
        i += 1
      }
      continue
    }
    if (inString) {
      out += c
      if (escaped) {
        escaped = false
      } else if (c === "\\") {
        escaped = true
      } else if (c === quote) {
        inString = false
      }
      continue
    }
    if (c === '"' || c === "'") {
      inString = true
      quote = c
      out += c
      continue
    }
    if (c === "/" && n === "/") {
      lineComment = true
      i += 1
      continue
    }
    if (c === "/" && n === "*") {
      blockComment = true
      i += 1
      continue
    }
    out += c
  }
  return removeTrailingCommas(out)
}

function removeTrailingCommas(input) {
  let out = ""
  let inString = false
  let quote = ""
  let escaped = false

  for (let i = 0; i < input.length; i += 1) {
    const c = input[i]
    if (inString) {
      out += c
      if (escaped) escaped = false
      else if (c === "\\") escaped = true
      else if (c === quote) inString = false
      continue
    }
    if (c === '"' || c === "'") {
      inString = true
      quote = c
      out += c
      continue
    }
    if (c === ",") {
      let j = i + 1
      while (j < input.length && /\s/.test(input[j])) j += 1
      if (input[j] === "}" || input[j] === "]") continue
    }
    out += c
  }
  return out
}

function readConfig(file) {
  if (!fs.existsSync(file)) return { $schema: "https://opencode.ai/config.json" }
  const raw = fs.readFileSync(file, "utf8")
  if (!raw.trim()) return { $schema: "https://opencode.ai/config.json" }
  return JSON.parse(stripJsonc(raw))
}

function mergeConfig(cfg) {
  cfg.$schema = cfg.$schema || "https://opencode.ai/config.json"
  if (tuneConfig) {
    cfg.tool_output = {
      ...(cfg.tool_output || {}),
      max_lines: coercePositiveInt(cfg.tool_output?.max_lines, 200, 200),
      max_bytes: coercePositiveInt(cfg.tool_output?.max_bytes, 8192, 8192),
    }
    cfg.compaction = {
      ...(cfg.compaction || {}),
      auto: true,
      prune: true,
      tail_turns: coercePositiveInt(cfg.compaction?.tail_turns, 2, 2),
    }
  }
  if (codingAgentInstructionPath) {
    cfg.instructions = Array.isArray(cfg.instructions) ? cfg.instructions : []
    if (!cfg.instructions.includes(codingAgentInstructionPath)) cfg.instructions.push(codingAgentInstructionPath)
  }
  if (removeInstructionPath && Array.isArray(cfg.instructions)) {
    cfg.instructions = cfg.instructions.filter((entry) => entry !== removeInstructionPath)
    if (cfg.instructions.length === 0) delete cfg.instructions
  }
  return cfg
}

function coercePositiveInt(value, fallback, cap) {
  const parsed = Number(value)
  if (!Number.isInteger(parsed) || parsed <= 0) return fallback
  return Math.min(parsed, cap)
}

fs.mkdirSync(path.dirname(target), { recursive: true })
if (fs.existsSync(target)) {
  const backup = `${target}.bak.${new Date().toISOString().replace(/[-:T]/g, "").slice(0, 14)}`
  fs.copyFileSync(target, backup)
  console.log(`Backed up ${target} to ${backup}`)
}

const config = mergeConfig(readConfig(target))
fs.writeFileSync(target, `${JSON.stringify(config, null, 2)}\n`)
console.log(`Updated OpenCode config at ${target}`)
