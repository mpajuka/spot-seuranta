//
//  ContentView.swift
//  test
//
//  Created by Miska Pajukangas on 2023-01-18.
//

import SwiftUI
import Charts


struct EPrice
{
    let currentTime: Int
    let currentPrice: Double
}


class APIParser : NSObject, XMLParserDelegate
{
    var previous = ""
    var current = ""
    var time = -1
    var price = 0.0
    var counter = 1
    var todayprices = [EPrice]()
    var tomorrowprices = [EPrice]()
    var previoustimes = [Int]()
    var priceNow = 0.0
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
        namespaceURI: String?, qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:])
    {
        current = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        if (string.trimmingCharacters(in: .whitespacesAndNewlines) != "")
        {
            if (current == "position")
            {
                time = (string as NSString).integerValue
                if (time == 24)
                {
                    time = 0
                }
                counter += 1
            }
            if (current == "price.amount")
            {
                price = (string as NSString).doubleValue
                price = price/10
                
            }
            if (time != -1 && price != 0.0 && current == "price.amount")
            {
                if (counter > 24 && counter < 73)
                {
                    let i = EPrice(currentTime: time, currentPrice: price)
                    if (previoustimes.contains(time))
                    {
                        tomorrowprices.append(i)
                    }
                    else
                    {
                        if (time == returnHour())
                        {
                            priceNow = price
                        }
                        todayprices.append(i)
                        previoustimes.append(time)
                    }
                }
            }
        }
        
    }
}


func returnHour() -> Int
{
    let today = Date()
    let currentHour = Calendar.current.component(.hour, from: today)
    return currentHour
}


extension Color
{
    init(hex: Int, opacity: Double = 1.0)
    {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}


struct ContentView: View
{
    @State private var entsotoday = [EPrice]()
    @State private var entsotomorrow = [EPrice]()
    @State private var showTomorrow = false
    @State private var tomorrowReleased = false
    @State private var showAlert = false
    @State var priceNow = 0.0
    
    var body: some View
    {
        NavigationView
        {
            VStack
            {
                Spacer()
                Text("Sähkön hinta on nyt")
                    .font(.largeTitle)
                Spacer()
                Text("\(String(format: "%.2f c/kWh", returnPriceNow() * returnCurrentVAT()))")
                    .font(.title)
                Text("(sis. ALV \(String(format: "%.0f", (returnCurrentVAT() - 1) * 100))%)")
                    .font(.footnote)
               
                Spacer()
                if (returnHour() == 23)
                {
                    Text("Uusi hinta päivittyy klo: 00:00")
                        .font(.callout)
                }
                else
                {
                    Text("Uusi hinta päivittyy klo " + "\(String(format: "%02d:00", returnHour() + 1))")
                        .font(.callout)
                }
                VStack
                {
                    Chart (entsotoday, id: \.currentTime)
                    { price in
                        BarMark(
                                x: .value("Aika", price.currentTime),
                                y: .value("Hinta", price.currentPrice * returnCurrentVAT())
                            )
                            .foregroundStyle(returnHour() == price.currentTime ? .green : .blue)
                    }
                    .frame(height: 175)
                    .chartXScale(domain: 0...23)
                    .chartXAxis
                    {
                        AxisMarks(preset: .aligned, values: .automatic(desiredCount: 24))
                    }
                    .chartYAxis
                    {
                        AxisMarks(preset: .aligned, position: .leading)
                    }
                    .offset(x:-5)
            
                }
                .scenePadding(.all)
                List(entsotoday, id: \.currentTime)
                { curPrice in
                    HStack(alignment: .top)
                    {
                        if (curPrice.currentTime == 23)
                        {
                            Text("23:00-00:00")
                                .foregroundColor(returnHour() == curPrice.currentTime ? .green : .blue)
                                .bold(returnHour() == curPrice.currentTime ? true : false)
                        }
                        else
                        {
                            Text("\((String(format: "%02d", curPrice.currentTime)))" + ":00-" + "\((String(format: "%02d", curPrice.currentTime+1)))" + ":00")
                                .foregroundColor(returnHour() == curPrice.currentTime ? .green : .blue)
                                .bold(returnHour() == curPrice.currentTime ? true : false)
                        }
                        Spacer()
                        Text("\((String(format: "%.2f c/kWh", curPrice.currentPrice * returnCurrentVAT())))")
                            .foregroundColor(returnHour() == curPrice.currentTime ? .green : .blue)
                            .bold(returnHour() == curPrice.currentTime ? true : false)
                    }
                }
            }
            .environment(\.defaultMinListRowHeight, 0)
            .task
            {
                await fetchDataFromAPI()
            }
        }
        Button(action:
        {
            if (tomorrowReleased == false)
            {
                showAlert = true
            }
            else
            {
                showTomorrow.toggle()
            }
        })
        {
            Text("Sähkön hinta huomenna")
                .bold()
                .padding(5)
        }
        .alert("Huomisen hintoja ei ole vielä julkaistu", isPresented: $showAlert)
        {
            Button("OK", role: .cancel) {}
        }
        .sheet(isPresented: $showTomorrow, content:
        {
            VStack
            {
                NavigationView
                {
                    VStack
                    {
                        VStack
                        {
                            Text("Sähkön hinta huomenna")
                                .font(.title)
                            Chart
                            {
                                ForEach(entsotomorrow, id: \.currentTime)
                                { price in
                                    BarMark(
                                        x: .value("Aika", price.currentTime),
                                        y: .value("Hinta", price.currentPrice * returnCurrentVAT())
                                    )
                                }
                            }
                            .frame(height: 175)
                            .chartXScale(domain: 0...23)
                            .chartXAxis
                            {
                                AxisMarks(preset: .aligned, values: .automatic(desiredCount: 24))
                            }
                            .chartYAxis
                            {
                                AxisMarks(position: .leading)
                            }
                        }
                        .scenePadding(.all)
                        List(entsotomorrow, id: \.currentTime)
                        { curPrice in
                            HStack(alignment: .top)
                            {
                                if (curPrice.currentTime == 23)
                                {
                                    Text("23:00-00:00")
                                        .foregroundColor(.blue)
                                }
                                else
                                {
                                    Text("\((String(format: "%02d", curPrice.currentTime)))" + ":00-" + "\((String(format: "%02d", curPrice.currentTime+1)))" + ":00")
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                Text("\((String(format: "%.2f c/kWh", curPrice.currentPrice * returnCurrentVAT())))")
                                    .foregroundColor(.blue)
                            }
                        }
                        .environment(\.defaultMinListRowHeight, 0)
                    }
                }
            }
        })
    }
    
    /**
        Returns the multiplication factor for the electricity price, based on Finland's current electricity VAT
        The dates between 2022-12-01 and 2023-04-30 have the effective VAT of 10% and dates outside
        of that range follow the usual 24% rate
        
        - Returns:The multiplication factor for calculating price with VAT included
     */
    func returnCurrentVAT() -> Double
    {

        var loweredVATStart = DateComponents()
        loweredVATStart.year = 2022
        loweredVATStart.month = 12
        loweredVATStart.day = 1
        loweredVATStart.hour = 0
        loweredVATStart.minute = 0
        loweredVATStart.second = 0
        
        var loweredVATEnd = DateComponents()
        loweredVATEnd.year = 2023
        loweredVATEnd.month = 4
        loweredVATEnd.day = 30
        loweredVATEnd.hour = 23
        loweredVATEnd.minute = 59
        loweredVATEnd.second = 59
        
        let userCalendar = Calendar.current
        let startDate = userCalendar.date(from: loweredVATStart)
        let endDate = userCalendar.date(from: loweredVATEnd)
        
        let today = Date()

        if startDate?.compare(today) == .orderedAscending && endDate?.compare(today) == .orderedDescending {
            return 1.1
        } else {
            return 1.24
        }
    }
    
    func returnPriceNow() -> Double
    {
        for price in entsotoday {
            if price.currentTime == returnHour() {
                return price.currentPrice
            }
        }
        return 0
    }
    
    func fetchDataFromAPI() async
    {
        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)
        let today = Calendar.current.component(.day, from: now)
        let yesterday = today - 1
        let tomorrow = today + 1
        let dateInterval = String(format: "%d-%02d-%02dT00:00Z/%d-%02d-%02dT00:00Z",
                                  year, month, yesterday, year, month, tomorrow )
        
        var apiKey: String
        {
            get
            {
                guard let filePath = Bundle.main.path(forResource: "entso", ofType: "plist")
                else
                {
                    fatalError("Couldnt find api file")
                }
                let plist = NSDictionary(contentsOfFile: filePath)
                guard let value = plist?.object(forKey: "API_KEY") as? String
                else
                {
                    fatalError("Couldnt find api key")
                }
                return value
            }
            
        }
        var entsoUrl = "https://web-api.tp.entsoe.eu/api?securityToken="
        let param = "&documentType=A44&in_Domain=10YFI-1--------U&out_Domain=10YFI-1--------U&timeInterval="
        entsoUrl.append(apiKey)
        entsoUrl.append(param)
        entsoUrl.append(dateInterval)
            
        guard let entsourl = URL(string: entsoUrl)
        else
        {
            print("Unable to fetch data from entso-e")
            return
        }
        
        do
        {
            let (data, _) = try await URLSession.shared.data(from: entsourl)
            let urlparser = APIParser()
            let xmlparser = XMLParser(data: data)
            xmlparser.delegate = urlparser
            xmlparser.parse()
            priceNow = urlparser.priceNow
            entsotoday = urlparser.todayprices
            entsotomorrow = urlparser.tomorrowprices
            if (entsotomorrow.count > 1)
            {
                tomorrowReleased = true
            }
        }
        catch
        {
            print("error")
            return
        }
    }
    
    struct ContentView_Previews: PreviewProvider
    {
        static var previews: some View
        {
            ContentView()
        }
    }
}

