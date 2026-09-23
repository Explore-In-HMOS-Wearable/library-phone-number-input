import { Country } from "../model/Country";
import { LengthMetrics } from "@kit.ArkUI";
import { i18n } from "@kit.LocalizationKit";

@Component
export struct SelectCountrySheet {
  @Link showSheet: boolean
  @Link selectedCountry: Country
  @Require allCountries: Country[]
  @State @Watch('setCountriesToShow') private input: string = '';
  @State private countriesToShow: Country[] = this.allCountries

  setCountriesToShow() {
    this.countriesToShow = this.input.length === 0 ? this.allCountries :
      this.allCountries.filter((c: Country) => {
        return this.nameOf(c.code).toLocaleLowerCase().includes(this.input.toLocaleLowerCase())
      })
  }

  aboutToAppear(): void {
    this.countriesToShow = this.allCountries
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.AI_search'))
          .fontColor([$r('sys.color.ohos_id_color_foreground')])
          .padding(8)

        TextInput({ text: this.input!!, placeholder: '...' })
          .borderRadius(0)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .padding({ start: LengthMetrics.vp(0), end: LengthMetrics.vp(8) })
          .backgroundColor(Color.Transparent)
      }
      .borderRadius(8)
      .backgroundColor($r('sys.color.textfield_bg_color'))

      ForEach(this.countriesToShow, (c: Country, index: number) => {
        if (index > 0) {
          Line({ height: 1, width: '100%' }).backgroundColor($r('sys.color.textfield_bg_color'))
        }

        Row({ space: 16 }) {
          Text(c.emoji)
          Text(this.nameOf(c.code)).layoutWeight(1)
          Text(c.prefix)
        }.width('100%').padding({ top: 16, bottom: 16 }).onClick(() => {
          this.selectedCountry = c
          this.showSheet = false
        })
      })
    }.padding(16)
  }

  nameOf(code: string) {
    return i18n.System.getDisplayCountry(code, i18n.System.getSystemLanguage())
  }
}