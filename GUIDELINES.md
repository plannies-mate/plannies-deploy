# GUIDELINES for AI's

Main Documents:
- SPECS-IN-COMMON.md - Specs shared with plannies-mate
- SPECS.MD - specs specific to this project
- IMPLEMENTATION.md - implementation decisions made
- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate) - This document
- README.md is - setup and usage by the Developer

# Goals

I am an Aussie Developer with a quirky sense of humour, I want clean subtle 
humour in wording - friendly without being "in your face"!

Note - ONLY do what I have asked! I welcome terse suggestions
but keep focused. When we have finished the task on hand I will
come back to what you suggested and tell you when you can go
wild!

## AI Interaction Principles

- Respect existing working code
- Minimize unnecessary rewrites
- Prioritize incremental improvements
- Ask clarifying questions before major changes
- Solve problems with the smallest possible intervention
- When in doubt, propose the least invasive solution

## AI Development Approach

### Understanding Requirements

- Always check SPEC.md first for exact requirements
- Don't make assumptions about data formats or processing rules
- Ask for clarification if requirements seem ambiguous
- Remember that simpler is usually better

## Code Quality Principles

- Write code that is immediately understandable
- Prioritize clarity over cleverness
- Comments explain "why", code explains "how"
- Keep functions short and focused (under 20 lines)
- Keep files focused on a single clear responsibility (under 200 lines)
- Choose readable variable names over terse ones
- Optimize for human comprehension first, computer efficiency second
- When in doubt, err on the side of simplicity and clarity

## AI Behavioral Safeguards

- Code is communication, not just instructions
- Prefer understanding over rewriting
- Demonstrate your reasoning before proposing changes
- Show the minimal path to solving the problem
- Explicitly state why a change is necessary
- If uncertain, ask clarifying questions first

## Defensive Programming Principles

- Treat all external input as potentially hostile and/or broken
- Validate and sanitize inputs rigorously
- Fail fast and explicitly when assumptions are violated
- Use language-specific safety mechanisms
- Prefer restrictive parsing over permissive methods
- Prioritize code clarity over excessively detailed defensive checks
- Remember: Code is a communication tool, not just machine instructions

### Code Development

- Focus on one component at a time
- Avoid over-engineering or adding unnecessary complexity
- Pay special attention to resource cleanup and error handling
- Consider edge cases but don't over-optimize prematurely

### Process Management

- Handle external processes carefully (initialization, cleanup)
- Use proper error handling for system calls
- Ensure resources are released appropriately
- Consider signal handling where appropriate

### Data Processing

- Follow specified rules exactly - don't add "improvements" without discussion
- Watch for assumptions about input formats
- Be careful with memory usage for larger datasets
- Consider rate limits when accessing external services

### Testing & Development

- Use limit parameters during development when available
- Test with small datasets first
- Verify output formats carefully
- Check resource cleanup during normal and error conditions

## Common AI Pitfalls to Avoid

- Adding complexity that wasn't requested
- Making assumptions about "standard" ways to process data
- Trying to optimize too early
- Missing cleanup of external resources
- Over-commenting obvious code
- Under-documenting complex logic (comments explain why, code should explain how)

## Communication

- Ask questions when requirements are unclear
- Propose simplifications when possible
- Identify potential issues early
- Be explicit about implementation trade-offs

Remember: The AI's role is to implement the specified requirements accurately and simply, not to enhance them without
discussion.

