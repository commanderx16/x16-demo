/* Typing Some Stuff On the Screen Slowly Using VBLANK
   By: Tim Soderstrom

   This is an example for the Commander x16 for how to use the VBLANK interrupt
   to type on the screen slowly. It hopefully is a decent example on how to
   use interrupts (at least VBLANK).

   It was written using Kick-Assembler but I tried to include everything you
   need here making porting it to other assemblers hopefully easy.

   For more information on the x16 and the VERA:
   https://github.com/commanderx16/x16-docs
*/

// Kernel Routines
.const CHROUT = $ffd2
.const CINT = $ff81

// VERA Addresses
.const VERAREG   = $9f20
.const VERAIEN   = $9f26
.const VERAISR   = $9f27

// Zero Page Addresses
.const STRING_POSITION = $01      // The current offset of the string
.const VBLANK_SKIP_MAX = $02      // How many VBLANKs to do nothing for
.const VBLANK_SKIP_COUNT = $03    // Count of current VBLANK skip

// Constants
.const VBLANK_MASK = %00000001    // A mask to make sure we set VERA correctly.
.const VBLANK_SKIPS = $0A         // A constant for how many VBLANKs to skip.

:BasicUpstart2(setup)

// Setup some things before we get going
setup:
  // Disable interrupts so we do not get distracted setting up code
  sei

  jsr CINT  // Clear the screen

  // Initialize Variables
  /* We set the VBLANK_SKIP_MAX to the constant we specified in VBLANK_SKIPS.
     This basically adds in a delay so the program "types slower" */
  ldx #VBLANK_SKIPS
  stx VBLANK_SKIP_MAX
  /* Set some counters to zero */
  ldx #$00
  stx VBLANK_SKIP_COUNT
  stx STRING_POSITION

  // Setup typing irq handler
  /* We load the address of our interrupt handler into a special memory
     location. Basically when an interrupt triggers, this is the
     routine the CPU will execute. */
  lda #<typing_irq
  sta $0314
  lda #>typing_irq
  sta $0315

  // Enable VBLANK Interrupt
  /* We will use VBLANK from the VERA as our time keeper, so we enable
     the VBLANK interupt */
  lda #VBLANK_MASK
  sta VERAIEN

  // Set our string position to 0
  ldx #0
  stx STRING_POSITION

// Main loop
loop:
  cli         // Enable interupts
  jmp loop    // Loop while we wait

/* Reset string position back to 0 and go back to main loop, effectively
   printing the string over and over and over ...
   We jump here from our interrupt handler when we have read to the
   end of the string. */
reset:
  ldx #$00
  stx STRING_POSITION
  jmp loop

/* The main typing interrupt handler. This is what does the actual work */
typing_irq:
  // Disable interrupts since we don't want to be interrupted (hah)
  sei

  /* Check to see if the VBLANK was triggered. This is in case the intterupt
     was triggered by something else. We just want VBLANK. */
  lda VERAISR       // Load contents of VERA's ISR
  and #VBLANK_MASK  // Mask first bit.
  clc
  cmp #VBLANK_MASK  // If it's not 1, we blanked, continue
  bcc loop          // if it's not 1, go back to loop

  // Clear the VBLANK Interrupt Status
  lda VERAISR
  and #VBLANK_MASK
  sta VERAISR

  /* This is an additional delay. We increment a counter on every VBLANK and
     once we reach the max, we continue. Otherwise we jump back to the main
     loop. This is what slows the typing down. */
  inc VBLANK_SKIP_COUNT   // increment delay counter
  ldy VBLANK_SKIP_COUNT   // load delay counter
  cpy VBLANK_SKIP_MAX     // compare delay count to max delay
  bcc loop                // if it's not equal, go back to loop

  // We have finished delaying, so we reset the counter and continue.
  ldx #$00
  stx VBLANK_SKIP_COUNT

  /* Finally print a character on the screen and increment the position for
     the next time */
  ldx   STRING_POSITION
  lda   msg,x
  jsr   CHROUT
  inc   STRING_POSITION

  /* We have reached the end of the string when A has a 0, so we jump to
     our reset routine so we can do it all over again. */
  cmp #0            // Compare A to end of string
  beq reset

  /* Otherwise, we jump back to the main loop. */
  jmp loop


/* Message to display on screen. Since we use a string pointed, it has to be
   less than 255. */
msg:  .text "ALL WORK AND NO PLAY MAKES JACK A DULL BOY "
      .byte 0
