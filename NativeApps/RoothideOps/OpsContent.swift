import SwiftUI

enum AppPalette {
	static let ink = Color(red: 0.11, green: 0.14, blue: 0.19)
	static let steel = Color(red: 0.20, green: 0.27, blue: 0.34)
	static let ocean = Color(red: 0.15, green: 0.60, blue: 0.72)
	static let mint = Color(red: 0.31, green: 0.75, blue: 0.62)
	static let amber = Color(red: 0.88, green: 0.66, blue: 0.30)
	static let coral = Color(red: 0.84, green: 0.39, blue: 0.42)
	static let shell = Color(red: 0.95, green: 0.97, blue: 0.98)
	static let fog = Color(red: 0.89, green: 0.92, blue: 0.95)
}

enum OpsContent {
	static let repoURL = URL(string: "https://github.com/iPwn666/iphone-roothide-ops")!

	static let metrics: [OpsMetric] = [
		OpsMetric(
			title: "APT",
			value: "Ciste",
			detail: "apt-get update i apt-get check jsou stabilni na zuzene sade zdroju.",
			symbol: "shippingbox.fill",
			tint: AppPalette.mint
		),
		OpsMetric(
			title: "SSH",
			value: "Pripraveno",
			detail: "root i mobile pristup je obnoveny pres WireGuard i USB localhost forwarding.",
			symbol: "dot.radiowaves.left.and.right",
			tint: AppPalette.ocean
		),
		OpsMetric(
			title: "Tweaky",
			value: "14 aktivnich",
			detail: "Debug a bypass-heavy injektory byly presunuty mimo zivou sadu.",
			symbol: "switch.2",
			tint: AppPalette.amber
		),
		OpsMetric(
			title: "Karantena",
			value: "14 presunuto",
			detail: "Rizikove injektory ziji v oddelene karantene, odkud jdou rychle vratit.",
			symbol: "archivebox.fill",
			tint: AppPalette.coral
		)
	]

	static let highlights: [String] = [
		"APT parser blocker zmizel po nahrazeni prerostle third-party sady repozitaru.",
		"Rozbity dpkg symlink chain je opraveny, takze instalace a upgrady znovu funguji.",
		"Roothide Manager je aktualizovany na 1.3.9 bez navratu hlucnych repo warningu.",
		"Remote workflow ted preferuje WireGuard, potom USB localhost forwarding a az nakonec on-device recovery."
	]

	static let articles: [OpsArticle] = [
		OpsArticle(
			title: "Stabilizacni audit",
			summary: "Co bylo opraveno, co zustalo aktivni a ktere injektory skoncily v karantene.",
			symbol: "checkmark.shield.fill",
			tint: AppPalette.mint,
			sections: [
				OpsSection(
					title: "Vychozi stav zarizeni",
					body: "Repo aktualne sleduje iPhone XS na iOS 16.3 s roothide, Sileo a ElleKit. Tahle appka je minena jako offline operatersky prehled prave pro tento typ setupu.",
					bullets: [
						"roothide jailbreak stack",
						"Sileo package workflow",
						"WireGuard a SSH fallback",
						"stability-first tweak profil"
					]
				),
				OpsSection(
					title: "Co se zmenilo",
					body: "Ziva tweak vrstva byla zuzena na minimum potrebne pro bezne pouzivani. Debuggery, bypassy, app patchery a hlucne vizualni hooky byly vytazeny z aktivni injekce.",
					bullets: [
						"EeveeSpotify, FLEX, ReScale, Satella a souvisejici injektory presunuty pryc",
						"SnowBoard, Cylinder, GoodWiFi a AppData zustaly aktivni",
						"Nejdriv se opravilo spojeni a package manager, az potom tweaky"
					]
				)
			]
		),
		OpsArticle(
			title: "Sprava balicku",
			summary: "Minimalni APT source strategie, cisty update flow a pravidla pro legacy repa.",
			symbol: "shippingbox.circle.fill",
			tint: AppPalette.ocean,
			sections: [
				OpsSection(
					title: "Minimalni sada zdroju",
					body: "Kuratorovany setup nechava jen feedy, ktere maji vyznam pro stabilni zaklad: Procursus, Chariz a Havoc. Legacy tweak repa se maji vracet jen tehdy, kdyz je konkretni nainstalovany balicek opravdu potrebuje.",
					bullets: [
						"apt.procurs.us",
						"repo.chariz.com",
						"havoc.app"
					]
				),
				OpsSection(
					title: "Operacni pravidla",
					body: "Rozbite, spatne formatovane nebo nepodepsane legacy feedy umi APT rozbit rychleji, nez stoji za to balicky, ktere nabizeji. Zalohuj source soubory, ciste vyhazuj stare listy a nech vypnute language fetches.",
					bullets: [
						"Pred upravou zalohovat kazdy .sources soubor",
						"Po vetsi zmene zdroju smazat stare list cache",
						"Nechat vypnute Acquire::Languages"
					]
				)
			]
		),
		OpsArticle(
			title: "Vzdaleny pristup",
			summary: "WireGuard-first remote pristup s USB a on-device fallback cestami.",
			symbol: "antenna.radiowaves.left.and.right.circle.fill",
			tint: AppPalette.amber,
			sections: [
				OpsSection(
					title: "Preferovane poradi",
					body: "Stabilni poradi je nejdriv WireGuard a SSH, potom USB localhost forwarding, a manualni obnova pres NewTerm nebo Pythonista az ve chvili, kdy je transport uz rozbity.",
					bullets: [
						"WireGuard a SSH pro beznou spravu",
						"USB pro recovery a rychle instalace",
						"Pythonista a NewTerm jen jako nouzovy fallback"
					]
				),
				OpsSection(
					title: "Po respringu",
					body: "Po ztrate transportu nezacinej package-manager chirurgii. Nejdriv obnov WireGuard, potom SSH, pak over launchd stav a teprve potom se vrat k tweakum nebo APT.",
					bullets: [
						"Overit stav tunelu",
						"Overit key auth",
						"Overit launch-on-demand SSH sockety"
					]
				)
			]
		),
		OpsArticle(
			title: "Pythonista workflow",
			summary: "Jak pouzit Pythonistu jako phone-side script runner, kdyz je SSH docasne nedostupne.",
			symbol: "terminal.fill",
			tint: AppPalette.steel,
			sections: [
				OpsSection(
					title: "Kdy dava smysl",
					body: "Pythonista je lehky most pro obnovu klicu, dump viditelnych cest a zapis recovery vystupu do Documents. Jakmile se vrati SSH, nema zustavat hlavni ridici vrstvou.",
					bullets: [
						"obnovit authorized_keys",
						"zapsat diagnostiku do Documents",
						"co nejdriv se vratit zpet na SSH"
					]
				)
			]
		),
		OpsArticle(
			title: "Soubory a SMB",
			summary: "Nejjednodussi nativni presun souboru mezi iPhonem a hostem bez dalsich appek.",
			symbol: "folder.badge.gearshape.fill",
			tint: AppPalette.amber,
			sections: [
				OpsSection(
					title: "Lokální Documents appky",
					body: "Roothide Ops zaklada ve svem Documents prostoru slozky Imports, Exports, Logs a Scripts. Jsou viditelne v aplikaci Soubory a hodi se pro rychle local-only handoff workflow.",
					bullets: [
						"Imports pro vstupni soubory",
						"Exports pro sdileni ven",
						"Logs pro diagnostiku",
						"Scripts pro nouzove helpery"
					]
				),
				OpsSection(
					title: "SMB share z hostu",
					body: "Na hostu je pripraveny share iPhoneDrop. V iPhonu otevri Soubory, klepni na tri tecky a zvol Pripojit k serveru. Pouzij aktualni LAN IP hostu nebo WireGuard IP, pokud je tunel aktivni.",
					bullets: [
						"sdileny nazev: iPhoneDrop",
						"LAN priklad: smb://192.168.50.42",
						"WireGuard priklad: smb://10.77.0.1",
						"Podslozky: Inbox, FromiPhone, Archives"
					]
				)
			]
		),
		OpsArticle(
			title: "eSign workflow",
			summary: "Kam eSign zapada pri IPA/TIPA inspekci bez nahrazovani source control a opakovatelnych buildu.",
			symbol: "shippingbox.and.arrow.backward.fill",
			tint: AppPalette.coral,
			sections: [
				OpsSection(
					title: "Vhodne pouziti",
					body: "eSign je uzitecny, kdyz potrebujes rychlou phone-side inspekci archivu, import repa nebo handoff do TrollStore. Vetsi upravy appky maji porad probihat ve source-controlled build workflow.",
					bullets: [
						"import IPA nebo TIPA",
						"prohlednout strukturu bundle",
						"poslat do TrollStore",
						"nepouzivat na vetsi refactory"
					]
				)
			]
		),
		OpsArticle(
			title: "MCP a host tooling",
			summary: "Linux-safe MCP a remote tooling pro spravu telefonu z ne-macOS hostu.",
			symbol: "network.badge.shield.half.filled",
			tint: AppPalette.mint,
			sections: [
				OpsSection(
					title: "Drzet to prakticky",
					body: "Na Linuxu davaji smysl filesystem, memory, GitHub, Playwright, Chrome DevTools a OpenAI docs MCP. AppleScript-based Apple MCP servery, ktere davaji smysl jen na macOS, nech mimo.",
					bullets: [
						"filesystem",
						"memory",
						"github",
						"playwright",
						"chrome devtools",
						"OpenAI docs"
					]
				)
			]
		),
		OpsArticle(
			title: "Apple Dev KB",
			summary: "Kratke pripominky ke Swiftu, praci s plist, Info.plist a on-device modelum.",
			symbol: "hammer.fill",
			tint: AppPalette.ocean,
			sections: [
				OpsSection(
					title: "Co je nejdulezitejsi",
					body: "Kdykoliv to jde, preferuj nativni frameworky pred hooky. Drz app logiku oddelene od UI, ber plist praci jako high-leverage zasah a validuj kazdou metadata zmenu.",
					bullets: [
						"Pouzivat plutil pro inspekci a linting",
						"Pred upravami zalohovat plist soubory",
						"Bundle metadata brat jako runtime-critical"
					]
				),
				OpsSection(
					title: "Starsi zarizeni",
					body: "Foundation Models jsou cisty smer od Apple, ale iPhone XS na iOS 16.3 porad potrebuje app-side AI, Vision a CoreML strategii misto predpokladu systemove Apple Intelligence.",
					bullets: [
						"Vision a CoreML zustavaji prakticke",
						"Cloud AI je volitelne, ne povinne",
						"Workflow drzet privacy-aware a reverzibilni"
					]
				)
			]
		),
		OpsArticle(
			title: "Bezpecnostni hranice",
			summary: "Co tohle repo neautomatizuje a proc je bezpecnejsi cesta reverzibilni udrzba.",
			symbol: "lock.shield.fill",
			tint: AppPalette.coral,
			sections: [
				OpsSection(
					title: "Mimo scope",
					body: "Tenhle projekt se vyhyba iCloud bypassum, activation tamperingu, forged eligibility trikum i cemukoliv, co by znamenalo publikovat privatni klice nebo ucetni tajemstvi ve verejnem toolingu.",
					bullets: [
						"Zadna manipulace se stavem uctu",
						"Zadny activation-lock bypass material",
						"Zadna publikovana tajemstvi"
					]
				)
			]
		)
	]

	static let recoveryFlows: [RecoveryFlow] = [
		RecoveryFlow(
			title: "Obnovit SSH pristup",
			summary: "Nejdriv vratit key auth, ne stav balicku.",
			symbol: "key.fill",
			tint: AppPalette.ocean,
			steps: [
				"Otevrit WireGuard a zvednout maintenance tunnel.",
				"Overit, ze mobile ucet porad ma validni authorized_keys.",
				"Root pristup kontrolovat az po navratu mobile pristupu.",
				"Jeste pred tweak zasahy zkontrolovat launch-on-demand SSH sockety."
			],
			note: "Kdyz padl transport, nezacinej APT ani tweak cleanupem."
		),
		RecoveryFlow(
			title: "Obnovit package manager",
			summary: "Nejdriv zuzit sources, teprve potom sahat na balicky.",
			symbol: "shippingbox.fill",
			tint: AppPalette.mint,
			steps: [
				"Zalohovat vsechny soubory v sources.list.d.",
				"Vypnout mrtve nebo malformed third-party feedy.",
				"Smazat stare list cache.",
				"Spustit apt-get update a potom apt-get check."
			],
			note: "Cista sada zdroju ma vetsi cenu nez desitky legacy repo."
		),
		RecoveryFlow(
			title: "Po respringu",
			summary: "Znovu postavit transport ve spravnem poradi.",
			symbol: "arrow.clockwise.circle.fill",
			tint: AppPalette.amber,
			steps: [
				"Zkontrolovat tunnel a sitovou cestu.",
				"USB localhost forwarding resit az po WireGuardu.",
				"Overit, ze SSH opravdu startuje, ne jen ze nekde posloucha port.",
				"Az potom se vracet k instalacim appek nebo upgradu balicku."
			],
			note: "Poslouchajici port neni totiz co zdravy SSH handshake."
		),
		RecoveryFlow(
			title: "Rollback tweaku",
			summary: "Karantena je lepsi nez mazani.",
			symbol: "archivebox.circle.fill",
			tint: AppPalette.coral,
			steps: [
				"Presunout rizikove injektory do disabled slozky s timestampem.",
				"Udelat jeden respring nebo sbreload.",
				"Znovu otestovat rozbitou appku nebo UI cestu.",
				"Vratit zpet jen presny injektor, ktery je porad potreba."
			],
			note: "Karantena drzi rollback rychly a zachovava package ownership."
		)
	]

	static let tools: [ToolkitItem] = [
		ToolkitItem(
			title: "ipa_tool.py",
			summary: "Inspekce, rozbaleni a znovuzabaleni IPA/TIPA archivu z hostu.",
			symbol: "shippingbox.and.arrow.forward.fill",
			location: "tools/ipa_tool.py",
			category: "Baleni"
		),
		ToolkitItem(
			title: "iphone_ax_recover.py",
			summary: "Accessibility-based recovery helper pro hledani a mackani viditelnych UI prvku pres USB.",
			symbol: "hand.tap.fill",
			location: "scripts/iphone_ax_recover.py",
			category: "Obnova"
		),
		ToolkitItem(
			title: "enable_ssh_key_template.py",
			summary: "Minimalni on-device template pro obnovu authorized_keys z environment promenne.",
			symbol: "key.horizontal.fill",
			location: "scripts/enable_ssh_key_template.py",
			category: "Obnova"
		),
		ToolkitItem(
			title: "phone-ssh-recovery.sh",
			summary: "Shell fallback pro update authorized_keys z vlozeneho public key.",
			symbol: "terminal.fill",
			location: "templates/phone-ssh-recovery.sh",
			category: "Obnova"
		),
		ToolkitItem(
			title: "codex-config-additions.toml",
			summary: "Zakladni Codex MCP additions pro filesystem, memory, docs a browser tooling.",
			symbol: "slider.horizontal.3",
			location: "templates/codex-config-additions.toml",
			category: "Host"
		),
		ToolkitItem(
			title: "iPhoneDrop SMB",
			summary: "Host-side SMB share otevritelny primo v aplikaci Soubory pres Pripojit k serveru.",
			symbol: "externaldrive.connected.to.line.below.fill",
			location: "smb://<host>/iPhoneDrop",
			category: "Host"
		)
	]
}
