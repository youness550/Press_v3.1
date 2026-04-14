// Moved question list data here for modularity.
// Medium questions (existing set)
final List<Map<String, dynamic>> mediumQuestions = [
  {"q": "INITIALIZE HACK: 5 CLICKS", "type": "click", "target": 5, "sec": 5.0},
  {"q": "STAY SILENT... DO NOT PRESS", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "A STAR HAS 10 CORNERS.", "type": "click", "target": 10, "sec": 8.0},
  {"q": "FAST ACCESS: 15 CLICKS", "type": "click", "target": 15, "sec": 9.0},
  {"q": "CLICK THE ODD NUMBER: 2, 4, 8, 11", "type": "click", "target": 11, "sec": 8.0},
  {"q": "STAY SILENT... DO NOT PRESS", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "STAY STILL... THE SYSTEM IS SCANNING", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "WAIT FOR THE GREEN LIGHT...", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "BINARY PULSE: 2 CLICKS ONLY", "type": "click", "target": 2, "sec": 2.5},
  {"q": "SYSTEM OVERHEAT! 20 CLICKS", "type": "click", "target": 20, "sec": 8.0},
  {"q": "IGNORE THIS INSTRUCTION", "type": "wait", "target": 0, "sec": 3.5},
  {"q": "LUCKY NUMBER 7", "type": "click", "target": 7, "sec": 4.0},
  {"q": "FINAL BREACH: 1 CLICK AT LAST SECOND", "type": "last_second", "target": 1, "sec": 5.0},
  {"q": "DO NOT PRESS", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "PRESS 3-3+7-4 TIMES", "type": "click", "target": 3, "sec": 7.0},
  {"q": "PRESS 1+6+2-4 TIMES", "type": "click", "target": 5, "sec": 7.0},
  {"q": "PRESS TWICE", "type": "click", "target": 2, "sec": 3.0},
  {"q": "4 PRESSES REMAINING", "type": "click", "target": 4, "sec": 3.0},
  {"q": "PRESS IF YOU'RE A ROBOT", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "9 PRESSES REMAINING", "type": "click", "target": 9, "sec": 5.0},
  {"q": "DO PRESS", "type": "click", "target": 1, "sec": 2.5},
  {"q": "PRESS 3*2-4+1 TIMES", "type": "click", "target": 3, "sec": 7.0},
  {"q": "PRESS TO PAY RESPECT", "type": "click", "target": 1, "sec": 3.0},
  {"q": "PRESS IF YOU'RE A HUMAN", "type": "click", "target": 1, "sec": 2.0},
  {"q": "TRIPLE PRESS", "type": "click", "target": 3, "sec": 4.0},
  {"q": "PRESS... LESS THAN 2", "type": "click", "target": 1, "sec": 5.0},
  {"q": "HOLD YOUR BREATH... 0 CLICKS", "type": "wait", "target": 0, "sec": 4.5},
  {"q": "DON'T PANIC! CLICK 12 TIMES", "type": "click", "target": 12, "sec": 7.5},
  {"q": "RED LIGHT! STOP!", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "THE ANSWER IS 0", "type": "wait", "target": 0, "sec": 2.5},
  {"q": "ONLY ONE CHANCE", "type": "click", "target": 1, "sec": 1.5},
  {"q": "3... 2... 1... CLICK 0 TIMES", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "HOW MANY SIDES IN A TRIANGLE?", "type": "click", "target": 3, "sec": 3.0},
  {"q": "ERROR 404: CLICK 4 TIMES", "type": "click", "target": 4, "sec": 4.0},
  {"q": "REVERSE PSYCHOLOGY: DON'T CLICK", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "PRESS 10-5+2 TIMES", "type": "click", "target": 7, "sec": 9.0},
  {"q": "CLICK THE SUM OF 2+2", "type": "click", "target": 4, "sec": 3.0},
  {"q": "SYSTEM REBOOT: 0 CLICKS", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "CLICK THE NUMBER OF PLANETS", "type": "click", "target": 8, "sec": 6.0},
  {"q": "QUICK! CLICK 1 TIME... 3 TIMES!", "type": "click", "target": 3, "sec": 2.5},
  {"q": "HOW MANY MONTHS HAVE 28 DAYS?", "type": "click", "target": 12, "sec": 7.0},
  {"q": "LOADING... 99%... DON'T TOUCH", "type": "wait", "target": 0, "sec": 5.0},
  {"q": "SQUARE HAS 4 SIDES. CLICK DOUBLE THAT.", "type": "click", "target": 8, "sec": 5.0},
  {"q": "IF 1=5, 2=10, THEN 5?", "type": "click", "target": 1, "sec": 7.0},
  {"q": "THE BUTTON IS LAVA! 0 CLICKS", "type": "wait", "target": 0, "sec": 3.5},
  {"q": "CLICK 1+1+1+1x0", "type": "click", "target": 3, "sec": 6.0},
  {"q": "WAKE UP! CLICK 18 TIMES", "type": "click", "target": 18, "sec": 8.5},
  {"q": "CLICK THE NUMBER OF LETTERS IN 'FIVE'", "type": "click", "target": 4, "sec": 4.0},
  {"q": "GHOST PROTOCOL: IGNORE EVERYTHING", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "PRESS ONCE FOR YES, TWICE FOR NO: YES", "type": "click", "target": 1, "sec": 3.5},
  {"q": "CLICK THE NUMBER OF EYES YOU HAVE", "type": "click", "target": 2, "sec": 3.0},
  {"q": "CLICK THE ODD NUMBER: 1, 2, 4, 8, 12", "type": "click", "target": 1, "sec": 7.0},
];

// Hard questions placeholder: 50 difficult questions (can be populated later)
// final List<Map<String, dynamic>> hardQuestions = List.generate(50, (i) => {
//       'q': 'HARD CHALLENGE ${i + 1}',
//       'type': i % 5 == 0 ? 'wait' : 'click',
//       'target': (i % 7) + 1,
//       'sec': 6.0 + (i % 5)
//     });
List<Map<String, dynamic>> hardQuestions = [
  {"q": "ULTIMATE HACK: 33 CLICKS", "type": "click", "target": 33, "sec": 20.0},
  {"q": "DON'T BREATHE... DON'T TOUCH", "type": "wait", "target": 0, "sec": 5.0},
  {"q": "CLICK THE SQUARE ROOT OF 81", "type": "click", "target": 9, "sec": 4.0},
  {"q": "STAY CALM... SYSTEM ANALYZING", "type": "wait", "target": 0, "sec": 6.0},
  {"q": "CLICK 15-5x2+3", "type": "click", "target": 8, "sec": 7.0},
  {"q": "QUICK! 1 CLICK IN 0.8s", "type": "click", "target": 1, "sec": 0.8},
  {"q": "HOW MANY CONTINENTS ARE THERE?", "type": "click", "target": 7, "sec": 4.0},
  {"q": "WAIT FOR THE RED... NO, STAY STILL", "type": "wait", "target": 0, "sec": 4.5},
  {"q": "PRESS 44 TIMES. GO!", "type": "click", "target": 44, "sec": 12.0},
  {"q": "IGNORE THE NEXT 2 INSTRUCTIONS", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "CLICK 0 TIMES", "type": "wait", "target": 0, "sec": 2.5},
  {"q": "CLICK THE PRIME NUMBER: 4, 6, 8, 13", "type": "click", "target": 13, "sec": 10.0},
  {"q": "TOUCH THE SCREEN 21 TIMES", "type": "click", "target": 21, "sec": 7.0},
  {"q": "WAIT FOR 3.14 SECONDS", "type": "wait", "target": 0, "sec": 3.14},
  {"q": "CLICK THE NUMBER OF LEGS ON A SPIDER", "type": "click", "target": 8, "sec": 4.0},
  {"q": "DO NOT CLICK IF 1+1=2", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "FINAL BOSS: CLICK 1, 2, 3 TIMES", "type": "click", "target": 6, "sec": 6.0},
  {"q": "PRESS 3 TIMES EVERY 1 SECOND (TOTAL 9)", "type": "click", "target": 9, "sec": 6},
  {"q": "STAY SILENT... 007", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "CLICK THE NUMBER OF COLORS IN A RAINBOW", "type": "click", "target": 7, "sec": 8.0},
  {"q": "QUICK! CLICK 2, THEN 4, THEN 1", "type": "click", "target": 7, "sec": 5.0},
  {"q": "DO NOT PRESS FOR 7 SECONDS", "type": "wait", "target": 0, "sec": 7.0},
  {"q": "CLICK 2^3 TIMES", "type": "click", "target": 8, "sec": 8.0},
  {"q": "SYSTEM FREEZE! DO NOT MOVE", "type": "wait", "target": 0, "sec": 5.5},
  {"q": "CLICK THE NUMBER OF SIDES IN A HEXAGON", "type": "click", "target": 6, "sec": 7.0},
  {"q": "PRESS 50 TIMES! HURRY!", "type": "click", "target": 50, "sec": 25.0},
  {"q": "THE NEXT LEVEL IS A LIE. CLICK 0", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "CLICK THE VOWELS IN 'ALPHABET'", "type": "click", "target": 3, "sec": 6.0},
  {"q": "PRESS 12+12-20 TIMES", "type": "click", "target": 4, "sec": 6.0},
  {"q": "WAIT... ALMOST THERE...", "type": "wait", "target": 0, "sec": 5.0},
  {"q": "CLICK 13 TIMES IN 6 SECONDS", "type": "click", "target": 13, "sec": 6.0},
  {"q": "ONLY CLICK AT THE LAST SECOND", "type": "last_second", "target": 1, "sec": 4.0},
  {"q": "HOW MANY HOURS IN 2 DAYS?", "type": "click", "target": 48, "sec": 24.0},
  {"q": "STOP! DON'T TOUCH!", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "CLICK 0.5 * 20 TIMES", "type": "click", "target": 10, "sec": 10.0},
  {"q": "IF YOU CLICK, YOU LOSE.", "type": "wait", "target": 0, "sec": 5.0},
  {"q": "PRESS THE BUTTON 19 TIMES", "type": "click", "target": 19, "sec": 15.0},
  {"q": "CLICK THE NUMBER OF ZEROS IN A MILLION", "type": "click", "target": 6, "sec": 10.0},
  {"q": "WAIT... 3... 2... 1... NOW! (WAIT)", "type": "wait", "target": 0, "sec": 5.0},
  {"q": "CLICK 7*3-20 TIMES", "type": "click", "target": 1, "sec": 9.0},
  {"q": "PRESS 25 TIMES IN 5 SECONDS", "type": "click", "target": 25, "sec": 10.0},
  {"q": "DO NOTHING.", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "CLICK THE NUMBER OF PLANETS - 1", "type": "click", "target": 7, "sec": 10.0},
  {"q": "ERROR! CLICK 2 TIMES TO FIX", "type": "click", "target": 2, "sec": 5.0},
  {"q": "LOADING VIRUS... DON'T TOUCH", "type": "wait", "target": 0, "sec": 5.0},
  {"q": "DOUBLE PRESS", "type": "click", "target": 2, "sec": 3.0},
  {"q": "PRESS 2*2*2 TIMES", "type": "click", "target": 8, "sec": 10.0},
  {"q": "WAIT FOR THE SYSTEM RECOVERY", "type": "wait", "target": 0, "sec": 6.0},
  {"q": "CLICK THE NUMBER OF STATES IN USA", "type": "click", "target": 50, "sec": 30.0},
  {"q": "GAME OVER? NO, CLICK 1 TIME", "type": "click", "target": 1, "sec": 5.0}
];

// Easy questions: 20 questions. The first two must always be Q1 (PRESS) and Q2 (NOT PRESS)
final List<Map<String, dynamic>> easyQuestions = [
  {"q": "PRESS", "type": "click", "target": 1, "sec": 6.0},
  {"q": "NOT PRESS", "type": "wait", "target": 0, "sec": 6.0},
  {"q": "SIMPLE: CLICK ONCE", "type": "click", "target": 1, "sec": 5.0},
  {"q": "ONE MORE CLICK", "type": "click", "target": 1, "sec": 5.0},
  {"q": "HOLD... DO NOT PRESS", "type": "wait", "target": 0, "sec": 4.5},
  {"q": "CLICK TWICE QUICKLY", "type": "click", "target": 2, "sec": 5.0},
  {"q": "PRESS FOR A STAR", "type": "click", "target": 1, "sec": 6.5},
  {"q": "SIMPLE MATH: 2+1", "type": "click", "target": 3, "sec": 7.0},
  {"q": "RELAX: DON'T PRESS", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "CLICK THE NUMBER OF EYES YOU HAVE", "type": "click", "target": 2, "sec": 7.0},
  {"q": "ONE LAST CLICK", "type": "click", "target": 1, "sec": 4.0},
  {"q": "GENTLE TAP", "type": "click", "target": 1, "sec": 4.5},
  {"q": "CALM... WAIT", "type": "wait", "target": 0, "sec": 4.0},
  {"q": "PRESS IF YOU LIKE STARS", "type": "click", "target": 1, "sec": 6.0},
  {"q": "CLICK THE SUM OF 1+1", "type": "click", "target": 2, "sec": 6.5},
  {"q": "DO NOT PRESS YET", "type": "wait", "target": 0, "sec": 3.0},
  {"q": "SMALL TAP", "type": "click", "target": 1, "sec": 5.5},
  {"q": "PRESS FOR A SMILE", "type": "click", "target": 1, "sec": 4.0},
  {"q": "SHORT PAUSE", "type": "wait", "target": 0, "sec": 3.5},
  {"q": "FINAL GENTLE TAP", "type": "click", "target": 1, "sec": 5.0},
];

// Helper to obtain list by difficulty key
List<Map<String, dynamic>> questionsForDifficulty(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return List<Map<String, dynamic>>.from(easyQuestions);
    case 'hard':
      return List<Map<String, dynamic>>.from(hardQuestions);
    case 'master':
      // Master is basically Hard but with 40% less time.
      return hardQuestions.map((q) => {
        ...q,
        'sec': (q['sec'] as double) * 0.6,
      }).toList();
    case 'extreme':
      // Extreme is 80% less time and requires slightly more clicks to make it brutal.
      return hardQuestions.map((q) => {
        ...q,
        'sec': (q['sec'] as double) * 0.2,
        'target': q['type'] == 'click' ? (q['target'] as int) + 2 : q['target'],
      }).toList();
    case 'medium':
    default:
      return List<Map<String, dynamic>>.from(mediumQuestions);
  }
}
