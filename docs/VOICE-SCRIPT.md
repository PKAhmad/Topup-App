# Voice Script — record these clips (Pashto first)

**How it works:** fixed sentences are one clip each (`prompt_*`). Numbers are
*composed* by the app from small clips (digits, tens, سل/زر...), so record the
number pieces carefully and evenly — same voice, same speed, quiet room.
Record in this order: Pashto (launch), then Dari, then English.
File names must match EXACTLY: `assets/audio/ps/<key>.mp3` (fa/en likewise).
The app already ships with silent placeholders under these names — recording
over a file is all it takes, no code change.

Voice direction: warm, clear, slow. A trusted family-member tone, not a newsreader.
For Pashto use natural Nangarhar/Eastern speech.

## Fixed prompts
| key | پښتو | دری | English |
|---|---|---|---|
| prompt_welcome | ښه راغلاست! دلته تاسو خپلو خپلوانو ته موبایل کرېډېټ لېږلی شئ. د پیل لپاره شنه تڼۍ کېکاږئ. | خوش آمدید! اینجا می‌توانید برای خانواده‌تان کریدیت موبایل بفرستید. برای شروع، دکمه سبز را فشار دهید. | Welcome! Here you can send mobile credit to your family. Press the green button to start. |
| prompt_choose_country | کوم هېواد ته کرېډېټ لېږئ؟ هغه هېواد وټاکئ. | به کدام کشور کریدیت می‌فرستید؟ آن کشور را انتخاب کنید. | Which country are you sending credit to? Choose that country. |
| prompt_enter_number | د هغه کس شمېره ولیکئ چې کرېډېټ ورته لېږئ. بیا لاندې تڼۍ کېکاږئ. | شماره کسی را بنویسید که برایش کریدیت می‌فرستید. بعد دکمه پایین را فشار دهید. | Write the number of the person you are sending credit to. Then press the button below. |
| prompt_number_is | تاسو دا شمېره ولیکله: | شما این شماره را نوشتید: | You entered this number: |
| prompt_confirm_number | ایا دا شمېره سمه ده؟ که سمه وي، شنه تڼۍ کېکاږئ. که غلطه وي، سره تڼۍ کېکاږئ. | آیا این شماره درست است؟ اگر درست است، دکمه سبز را فشار دهید. اگر اشتباه است، دکمه سرخ را فشار دهید. | Is this number correct? If it is correct, press the green button. If it is wrong, press the red button. |
| prompt_invalid_number | دا شمېره سمه نه ده. مهرباني وکړئ بیا یې وګورئ او بیا یې ولیکئ. | این شماره درست نیست. لطفاً دوباره بررسی کنید و بنویسید. | This number is not correct. Please check it and write it again. |
| prompt_choose_amount | څومره کرېډېټ لېږئ؟ یو مقدار وټاکئ. | چقدر کریدیت می‌فرستید؟ یک مبلغ را انتخاب کنید. | How much credit are you sending? Choose an amount. |
| prompt_you_chose | تاسو وټاکل: | شما انتخاب کردید: | You chose: |
| prompt_review | مهرباني وکړئ معلومات وګورئ. | لطفاً جزئیات را بررسی کنید. | Please check the details. |
| prompt_you_send | تاسو لېږئ: | شما می‌فرستید: | You are sending: |
| prompt_to_number | دې شمېرې ته: | به این شماره: | to this number: |
| prompt_total_is | ټول قیمت دی: | قیمت کل است: | The total price is: |
| prompt_processing | مهرباني وکړئ انتظار وکړئ. ستاسو کرېډېټ لېږل کېږي. | لطفاً صبر کنید. کریدیت شما در حال ارسال است. | Please wait. Your credit is being sent. |
| prompt_success | مبارک شه! ستاسو کرېډېټ په بریالیتوب سره ولېږل شو. | مبارک! کریدیت شما موفقانه ارسال شد. | Congratulations! Your credit was sent successfully. |
| prompt_failed_refund | بخښنه غواړو، کرېډېټ ونه لېږل شو. اندېښنه مه کوئ، ستاسو پیسې به بېرته ستاسو کارت ته ستونې شي. | متاسفیم، کریدیت ارسال نشد. نگران نباشید، پول شما به کارت‌تان برگردانده می‌شود. | Sorry, the credit was not sent. Do not worry, your money will be returned to your card. |
| prompt_error | ستونزه رامنځته شوه. مهرباني وکړئ بیا هڅه وکړئ. | مشکلی پیش آمد. لطفاً دوباره تلاش کنید. | Something went wrong. Please try again. |
| prompt_history | دا ستاسو پخواني لېږل دي. | این ارسال‌های قبلی شما است. | These are your previous top-ups. |

## Number pieces (record each word alone, evenly)
| group | keys | پښتو | دری | English |
|---|---|---|---|---|
| digits | digit_0..digit_9 | صفر، یو، دوه، درې، څلور، پنځه، شپږ، اووه، اته، نهه | صفر، یک، دو، سه، چهار، پنج، شش، هفت، هشت، نه | zero..nine |
| teens | teen_11..teen_19 | یوولس، دولس، دیارلس، څوارلس، پنځلس، شپاړس، اوولس، اتلس، نولس | یازده، دوازده، سیزده، چهارده، پانزده، شانزده، هفده، هجده، نوزده | eleven..nineteen |
| tens | tens_10, tens_20..tens_90 | لس، شل، دېرش، څلوېښت، پنځوس، شپېته، اویا، اتیا، نوي | ده، بیست، سی، چهل، پنجاه، شصت، هفتاد، هشتاد، نود | ten, twenty..ninety |
| tens suffix (Pashto only) | tensx_20..tensx_90 | ویشت، دېرش، څلوېښت، پنځوس، شپېته، اویا، اتیا، نوي | — (not used in Dari) | — (not used in English) |
| scales | scale_hundred, scale_thousand | سل، زر | صد، هزار | hundred, thousand |
| joiners | word_and, word_point | او، اشاریه | و، ممیز | and, point |
| currencies | cur_AFN, cur_EUR, cur_USD, cur_PKR, cur_GBP, cur_AED, cur_SAR, cur_TRY, cur_SEK | افغانۍ، یورو، ډالر، روپۍ، پونډ، درهم، ریال، لیره، کرون | افغانی، یورو، دالر، روپیه، پوند، درهم، ریال، لیره، کرون | Afghanis, euros, dollars, rupees, pounds, dirhams, riyals, lira, kronor |
