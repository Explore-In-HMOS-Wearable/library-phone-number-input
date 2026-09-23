import { SelectCountrySheet } from "../view/SelectCountrySheet";
import { i18n } from "@kit.LocalizationKit";
import { LengthMetrics } from "@kit.ArkUI";
import { PhoneNumber } from "../model/PhoneNumber";
import { Country } from "../model/Country";
import { util } from "@kit.ArkTS";

/**
 * PhoneInput Field
 *
 * @param {PhoneNumber} phoneNumber '@Link' for '@State PhoneNumber'
 * @param {string} initialCountryCode Two letter country code, default: 'TR'
 *
 **/
@Component
export struct PhoneNumberInput {
  @Link phoneNumber: PhoneNumber
  initialCountryCode?: string
  //
  @State private allCountries: Country[] = this.loadCountries()
  @State @Watch('setPhoneNumber') private selectedCountry: Country = { code: "TR", prefix: "+90", emoji: "🇹🇷" }
  //
  private controller: TextInputController = new TextInputController();
  @State @Watch('setPhoneNumber') private input: string = '';
  private lastCaretIndex: number = 0
  private newCaretIndex: number = -1
  //
  @State isValid: boolean = true
  @State private showSelectCountrySheet: boolean = false
  @State private rowHeight: Length = 0

  setPhoneNumber() {
    const formatter = new i18n.PhoneNumberFormat(this.selectedCountry.code, { type: 'TYPING' })
    this.isValid = formatter.isValidNumber(`${this.selectedCountry.prefix}${this.input}`)

    this.phoneNumber = {
      countryCode: this.selectedCountry.code,
      prefix: this.selectedCountry.prefix,
      body: this.input,
      isValid: this.isValid
    }
  }

  aboutToAppear(): void {
    if (this.initialCountryCode !== undefined) {
      const country = this.allCountries.find((c: Country) => c.code === this.initialCountryCode)
      if (country !== undefined) {
        this.selectedCountry = country
      }
    }
  }

  build() {
    Row() {
      Row({ space: 4 }) {
        Text(this.selectedCountry.emoji)
        Text(this.selectedCountry.prefix).layoutWeight(1).minFontSize(12).maxFontSize(16).maxLines(1)
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontColor([$r('sys.color.ohos_id_color_foreground')])
      }
      .onClick(() => {
        this.showSelectCountrySheet = true
      })
      .bindSheet(this.showSelectCountrySheet!!, this.SelectCountrySheetBuilder(), {
        maskColor: Color.Gray,
        preferType: SheetType.CENTER
      })
      .width(100)
      .height(this.rowHeight)
      .padding(8)

      TextInput({ text: this.input, placeholder: '...', controller: this.controller })
        .borderRadius(0)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
        .padding({ start: LengthMetrics.vp(0), end: LengthMetrics.vp(8) })
        .backgroundColor(Color.Transparent)
        .type(InputType.PhoneNumber)
        .onWillChange((info) => {
          this.lastCaretIndex = this.controller.getCaretOffset().index

          if (info.content === '') {
            return true
          }

          // check if info.content contains anything other than numbers, space, or -, or () ()-
          if (!/^[\d ()-]+$/.test(info.content)) {
            return false
          }

          if (this.input !== info.content &&
            this.formatNumber(info.content, this.selectedCountry.code) === this.input) {
            return false
          }

          return true
        })
        .onChange((val: string) => {
          const formatted = this.formatNumber(val, this.selectedCountry.code)
          if (val === formatted) { // value formatted, set caret
            this.setCaret()
          } else { // value changed, calculate caret
            this.calculateCaret(formatted)
          }

          this.input = formatted
        })
    }
    .backgroundColor($r('sys.color.textfield_bg_color'))
    .borderRadius(8)
    .borderWidth(1)
    .borderColor(this.isValid ? Color.Transparent : Color.Red)
    .onAreaChange((_: Area, newArea: Area) => {
      this.rowHeight = newArea.height as number - 2
    })
  }

  formatNumber(rawInput: string, countryCode: string): string {
    const onlyDigits = rawInput.replace(/\D/g, '') // clear extra characters from raw input
    try {
      const formatter = new i18n.PhoneNumberFormat(countryCode, { type: 'TYPING' })
      const formatted = formatter.format(onlyDigits)
      return formatted.trim()
    } catch (error) {
      return onlyDigits // If formatting fails, just return the raw numbers
    }
  }

  calculateCaret(newFormatted: string) {
    if (this.lastCaretIndex === this.input.length) { // caret is at the end
      this.newCaretIndex = newFormatted.length // put caret at the end
      return
    }

    const oldTxtNoSpaceLen = this.input.replaceAll(' ', '').length
    const newTxtNoSpaceLen = newFormatted.replaceAll(' ', '').length
    const changeLen = newTxtNoSpaceLen - oldTxtNoSpaceLen
    const oldTxtSubNumLen = this.input.substring(0, this.lastCaretIndex).replaceAll(' ', '').length
    const expectedTxtSubNumLen = changeLen < -1 ? oldTxtSubNumLen : oldTxtSubNumLen + changeLen

    if (expectedTxtSubNumLen === 0) {
      this.newCaretIndex = 0
      return
    }

    let digitCount = 0
    for (let i = 0; i < newFormatted.length; i++) {
      if (/[0-9]/.test(newFormatted[i])) {
        digitCount++;

        if (digitCount === expectedTxtSubNumLen) {
          this.newCaretIndex = i + 1;
          break
        }
      }
    }
  }

  setCaret() {
    if (this.newCaretIndex > -1) {
      this.controller.caretPosition(this.newCaretIndex);
      this.newCaretIndex = -1
    }
  }

  loadCountries() {
    const rawData = this.getUIContext().getHostContext()!.resourceManager.getRawFileContentSync('codes.json')
    const jsonString = new util.TextDecoder().decodeToString(rawData)
    return JSON.parse(jsonString) as Country[];
  }

  @Builder
  SelectCountrySheetBuilder() {
    SelectCountrySheet({
      showSheet: this.showSelectCountrySheet,
      selectedCountry: this.selectedCountry,
      allCountries: this.allCountries
    })
  }
}