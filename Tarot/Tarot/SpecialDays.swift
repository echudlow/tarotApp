//
//  SpecialDays.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/3/26.
//
//  Which spreads open on which days. Moon dates are computed ahead of time (Meeus,
//  accurate to a few minutes) for 2026 through 2045, so no network is needed.
//  Add new holiday spreads by adding a rule in `windowDates(for:)`.

import Foundation

enum SpecialDays {
    /// A moon spread stays open for this many days either side of the moon (3 = a week in all).
    static let moonWindowDays = 3
    /// The Year Ahead opens this many days before and after New Year's Eve.
    static let yearWindowDays = 3

    // Unix seconds (UTC) of each new moon and full moon.
    private static let newMoons: [TimeInterval] = [
        1768765963, 1771329723, 1773883471, 1776426775, 1778961727, 1781492103,
        1784022251, 1786556219, 1789097224, 1791647409, 1794207737, 1796777534,
        1799353495, 1801929395, 1804498196, 1807055495, 1809601140, 1812138049,
        1814670157, 1817201141, 1819734098, 1822271796, 1824817019, 1827372290,
        1829938372, 1832512382, 1835087877, 1837657919, 1840218454, 1842769023,
        1845311310, 1847847756, 1850381074, 1852914258, 1855450624, 1857993481,
        1860545176, 1863105873, 1865673109, 1868242792, 1870810861, 1873374192,
        1875930702, 1878479534, 1881021417, 1883558721, 1886094911, 1888633472,
        1891176742, 1893725381, 1896278869, 1898836508, 1901397779, 1903961555,
        1906525302, 1909085683, 1911640283, 1914188878, 1916733320, 1919276260,
        1921819628, 1924363961, 1926909082, 1929455352, 1932004163, 1934557044,
        1937114254, 1939674302, 1942234841, 1944793980, 1947350870, 1949905305,
        1952457029, 1955005580, 1957550813, 1960093449, 1962635067, 1965177564,
        1967722551, 1970271151, 1972824134, 1975381945, 1977944260, 1980509254,
        1983073567, 1985633633, 1988187471, 1990735223, 1993278229, 1995817913,
        1998355587, 2000893008, 2003432843, 2005978376, 2008532405, 2011095605,
        2013665334, 2016236389, 2018803644, 2021364155, 2023917071, 2026462513,
        2029001181, 2031534775, 2034066366, 2036600124, 2039140395, 2041690442,
        2044251179, 2046820607, 2049394508, 2051967835, 2054535771, 2057094593,
        2059642673, 2062181026, 2064712831, 2067242352, 2069773914, 2072311194,
        2074856846, 2077412366, 2079977902, 2082551509, 2085128285, 2087701207,
        2090264252, 2092815228, 2095355844, 2097889801, 2100421036, 2102952933,
        2105488313, 2108029821, 2110580086, 2113140888, 2115711292, 2118286478,
        2120859426, 2123424525, 2125979718, 2128525870, 2131065148, 2133600115,
        2136133541, 2138668487, 2141208207, 2143755533, 2146311725, 2148875578,
        2151443747, 2154012222, 2156577614, 2159137478, 2161690338, 2164236018,
        2166775961, 2169313049, 2171850779, 2174392036, 2176938165, 2179489021,
        2182043908, 2184602415, 2187164122, 2189727517, 2192289712, 2194847663,
        2197399852, 2199946996, 2202491349, 2205035175, 2207579532, 2210124327,
        2212669483, 2215215985, 2217765635, 2220319709, 2222877832, 2225438136,
        2227998436, 2230557265, 2233113986, 2235668178, 2238219199, 2240766476,
        2243310192, 2245851587, 2248392605, 2250935223, 2253481000, 2256031053,
        2258586170, 2261146587, 2263711285, 2266277417, 2268840993, 2271398778,
        2273949734, 2276494755, 2279035416, 2281573204, 2284109731, 2286647322,
        2289189141, 2291738501, 2294297433, 2296865013, 2299436926, 2302007387,
        2304571990, 2307128849, 2309677741, 2312219186, 2314754475, 2317286111,
        2319817869, 2322354189, 2324899080, 2327454781, 2330020704, 2332593467,
        2335168114, 2337739480, 2340303138, 2342856353, 2345398931, 2347933196,
        2350463089, 2352993062, 2355527193, 2358068642, 2360619419, 2363180295,
        2365750414, 2368326349, 2370901880, 2373470109, 2376026824, 2378572024,
        2381108727, 2383640944, 2386172390, 2388706096, 2391244646, 2393790569,
        2396346123,
    ]

    private static let fullMoons: [TimeInterval] = [
        1767434605, 1769983801, 1772537932, 1775095987, 1777656264, 1780217178,
        1782777449, 1785335770, 1787890723, 1790441350, 1792987919, 1795532030,
        1798075719, 1800620268, 1803165839, 1805712248, 1808260051, 1810810766,
        1813365896, 1815925532, 1818487755, 1821049447, 1823608052, 1826162780,
        1828714157, 1831262614, 1833807850, 1836349594, 1838888830, 1841428171,
        1843970978, 1846519910, 1849075847, 1851637706, 1854203132, 1856769450,
        1859334010, 1861894108, 1864447424, 1866993040, 1869532024, 1872067060,
        1874601511, 1877138605, 1879681014, 1882230742, 1884789013, 1887355691,
        1889928202, 1892501201, 1895068477, 1897626017, 1900173416, 1902712826,
        1905247173, 1907779278, 1910311932, 1912848289, 1915391908, 1917946045,
        1920511861, 1923086467, 1925663180, 1928234803, 1930797005, 1933348900,
        1935891613, 1938427130, 1940958101, 1943487965, 1946020873, 1948561124,
        1951112016, 1953674350, 1956245602, 1958820751, 1961394185, 1963961172,
        1966518586, 1969065453, 1971603186, 1974135135, 1976665657, 1979199073,
        1981738754, 1984286585, 1986842994, 1989407268, 1991977476, 1994549860,
        1997119061, 1999680187, 2002231177, 2004773339, 2007310080, 2009845245,
        2012381904, 2014921954, 2017466567, 2020016882, 2022573936, 2025137463,
        2027704769, 2030271368, 2032833257, 2035388683, 2037938084, 2040482972,
        2043025023, 2045565771, 2048106760, 2050649705, 2053196236, 2055747269,
        2058302545, 2060860846, 2063420738, 2065981038, 2068540611, 2071098033,
        2073651842, 2076201373, 2078747373, 2081291631, 2083835809, 2086380563,
        2088925811, 2091471793, 2094019807, 2096571751, 2099128790, 2101690159,
        2104253155, 2106814531, 2109372271, 2111926123, 2114476534, 2117023468,
        2119566523, 2122106065, 2124644090, 2127183905, 2129728851, 2132280950,
        2134840188, 2137404726, 2139971812, 2142538537, 2145101948, 2147659232,
        2150208601, 2152750212, 2155286196, 2157819844, 2160354654, 2162893702,
        2165439410, 2167993463, 2170556514, 2173127256, 2175701466, 2178272778,
        2180835606, 2183387742, 2185930396, 2188466433, 2190998895, 2193530635,
        2196064623, 2198604236, 2201153007, 2203713382, 2206284586, 2208861471,
        2211436494, 2214003590, 2216560318, 2219107097, 2221645663, 2224178403,
        2226708387, 2229239430, 2231775808, 2234321418, 2236878385, 2239445753,
        2242019493, 2244594095, 2247164380, 2249726481, 2252278385, 2254820362,
        2257354882, 2259885902, 2262417843, 2264954569, 2267498609, 2270050927,
        2272611238, 2275178280, 2277749421, 2280320192, 2282885357, 2285441333,
        2287987794, 2290527226, 2293063363, 2295599682, 2298138528, 2300681176,
        2303228565, 2305781787, 2308341460, 2310906357, 2313472968, 2316037017,
        2318595644, 2321148270, 2323695906, 2326240071, 2328782194, 2331323600,
        2333865756, 2336410282, 2338958505, 2341510861, 2344066745, 2346625012,
        2349184596, 2351744557, 2354303671, 2356860302, 2359413040, 2361961637,
        2364507260, 2367051647, 2369595941, 2372140365, 2374684992, 2377230753,
        2379779580, 2382333397, 2384892686, 2387455704, 2390019134, 2392579908,
        2395136648, 2397689401,
    ]

    /// Spreads that are only open on certain days.
    static func isGated(_ spreadID: String) -> Bool {
        spreadID == "new_moon" || spreadID == "full_moon" || spreadID == "year_ahead"
    }

    /// The middle day of each opening, from the start of last year onward.
    private static func centerDays(for spreadID: String) -> [Date] {
        let cal = Calendar.current
        switch spreadID {
        case "new_moon":
            return newMoons.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0)) }
        case "full_moon":
            return fullMoons.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0)) }
        case "year_ahead":
            let year = cal.component(.year, from: Date())
            return ((year - 1)...(year + 1)).compactMap {
                cal.date(from: DateComponents(year: $0, month: 12, day: 31))
            }
        default:
            return []
        }
    }

    /// How many days either side of the center day the spread stays open.
    private static func slack(for spreadID: String) -> Int {
        spreadID == "year_ahead" ? yearWindowDays : moonWindowDays
    }

    /// True when the spread can be opened on this date. Debug builds are always open,
    /// so everything can be tested any day.
    static func isOpen(_ spreadID: String, on date: Date = Date()) -> Bool {
        guard isGated(spreadID) else { return true }
        #if DEBUG
        return true
        #else
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        let n = slack(for: spreadID)
        return centerDays(for: spreadID).contains {
            abs(cal.dateComponents([.day], from: $0, to: today).day ?? 999) <= n
        }
        #endif
    }

    /// The first day of the next opening, for the "opens on" label.
    static func nextOpening(_ spreadID: String, after date: Date = Date()) -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        let n = slack(for: spreadID)
        for center in centerDays(for: spreadID).sorted() {
            guard let start = cal.date(byAdding: .day, value: -n, to: center),
                  let end = cal.date(byAdding: .day, value: n, to: center) else { continue }
            if end >= today { return max(start, today) }
        }
        return nil
    }

    /// Short label for the Read page, like "OPENS NOV 23".
    static func opensLabel(_ spreadID: String) -> String {
        guard let d = nextOpening(spreadID) else { return "COMING SOON" }
        return "OPENS " + d.formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }

    /// The middle day of the window that is open right now, if any.
    private static func currentCenter(for spreadID: String) -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let n = slack(for: spreadID)
        return centerDays(for: spreadID).first {
            abs(cal.dateComponents([.day], from: $0, to: today).day ?? 999) <= n
        }
    }

    // MARK: - "It's open" announcement, shown once per opening

    private static func announcedKey(_ spreadID: String) -> String {
        let stamp = currentCenter(for: spreadID)?.timeIntervalSince1970 ?? 0   // 0 in debug builds
        return "announced_\(spreadID)_\(Int(stamp))"
    }

    /// The first open spread the person has not been told about yet.
    static func unseenAnnouncement() -> String? {
        let order = ["year_ahead", "full_moon", "new_moon"]
        return order.first { isOpen($0) && !UserDefaults.standard.bool(forKey: announcedKey($0)) }
    }

    static func markAnnounced(_ spreadID: String) {
        UserDefaults.standard.set(true, forKey: announcedKey(spreadID))
    }

    /// Label for a spread that is open right now, like "OPEN NOW · ENDS NOV 27".
    static func closesLabel(_ spreadID: String) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let n = slack(for: spreadID)
        for c in centerDays(for: spreadID) {
            let off = cal.dateComponents([.day], from: c, to: today).day ?? 999
            if abs(off) <= n, let end = cal.date(byAdding: .day, value: n, to: c) {
                return "OPEN NOW · ENDS " + end.formatted(.dateTime.month(.abbreviated).day()).uppercased()
            }
        }
        return "OPEN NOW"
    }

    /// Upcoming special days across all gated spreads, soonest first (for a calendar view).
    static func upcoming(limit: Int = 12) -> [(date: Date, spreadID: String)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var items: [(Date, String)] = []
        for id in ["new_moon", "full_moon", "year_ahead"] {
            for c in centerDays(for: id) where c >= today {
                items.append((c, id))
            }
        }
        return items.sorted { $0.0 < $1.0 }.prefix(limit).map { (date: $0.0, spreadID: $0.1) }
    }
}
