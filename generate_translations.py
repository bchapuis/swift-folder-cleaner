#!/usr/bin/env python3
"""Generate complete .xcstrings file with all 10 language translations"""

import json

# Translation dictionary: English -> {language_code: translation}
translations = {
    "Cancel": {
        "de": "Abbrechen",
        "es": "Cancelar",
        "fr": "Annuler",
        "zh-Hans": "取消",
        "pt": "Cancelar",
        "ja": "キャンセル",
        "ru": "Отменить",
        "ko": "취소",
        "it": "Annulla"
    },
    "Cancel scan": {
        "de": "Scan abbrechen",
        "es": "Cancelar escaneo",
        "fr": "Annuler l'analyse",
        "zh-Hans": "取消扫描",
        "pt": "Cancelar verificação",
        "ja": "スキャンをキャンセル",
        "ru": "Отменить сканирование",
        "ko": "스캔 취소",
        "it": "Annulla scansione"
    },
    "Clear filename filter": {
        "de": "Dateinamenfilter löschen",
        "es": "Borrar filtro de nombre",
        "fr": "Effacer le filtre de nom",
        "zh-Hans": "清除文件名筛选",
        "pt": "Limpar filtro de nome",
        "ja": "ファイル名フィルターをクリア",
        "ru": "Очистить фильтр имени",
        "ko": "파일 이름 필터 지우기",
        "it": "Cancella filtro nome"
    },
    "Click \"Scan Folder\" to analyze disk usage": {
        "de": "Klicken Sie auf \"Ordner scannen\", um die Festplattennutzung zu analysieren",
        "es": "Haga clic en \"Escanear carpeta\" para analizar el uso del disco",
        "fr": "Cliquez sur \"Analyser le dossier\" pour analyser l'utilisation du disque",
        "zh-Hans": "点击\"扫描文件夹\"以分析磁盘使用情况",
        "pt": "Clique em \"Verificar pasta\" para analisar o uso do disco",
        "ja": "「フォルダーをスキャン」をクリックしてディスク使用量を分析",
        "ru": "Нажмите \"Сканировать папку\" для анализа использования диска",
        "ko": "\"폴더 스캔\"을 클릭하여 디스크 사용량 분석",
        "it": "Fai clic su \"Scansiona cartella\" per analizzare l'uso del disco"
    },
    "Delete": {
        "de": "Löschen",
        "es": "Eliminar",
        "fr": "Supprimer",
        "zh-Hans": "删除",
        "pt": "Excluir",
        "ja": "削除",
        "ru": "Удалить",
        "ko": "삭제",
        "it": "Elimina"
    },
    "Enter text or wildcards to filter files by name. Use asterisk for any characters.": {
        "de": "Geben Sie Text oder Platzhalter ein, um Dateien nach Namen zu filtern. Verwenden Sie Sternchen für beliebige Zeichen.",
        "es": "Ingrese texto o comodines para filtrar archivos por nombre. Use asterisco para cualquier carácter.",
        "fr": "Saisissez du texte ou des caractères génériques pour filtrer les fichiers par nom. Utilisez l'astérisque pour n'importe quel caractère.",
        "zh-Hans": "输入文本或通配符以按名称筛选文件。使用星号表示任意字符。",
        "pt": "Digite texto ou curingas para filtrar arquivos por nome. Use asterisco para qualquer caractere.",
        "ja": "テキストまたはワイルドカードを入力して、名前でファイルをフィルター。任意の文字にはアスタリスクを使用。",
        "ru": "Введите текст или подстановочные знаки для фильтрации файлов по имени. Используйте звездочку для любых символов.",
        "ko": "이름으로 파일을 필터링하려면 텍스트 또는 와일드카드를 입력하세요. 모든 문자에 별표를 사용하세요.",
        "it": "Inserisci testo o caratteri jolly per filtrare i file per nome. Usa l'asterisco per qualsiasi carattere."
    },
    "Filename filter": {
        "de": "Dateinamenfilter",
        "es": "Filtro de nombre",
        "fr": "Filtre de nom",
        "zh-Hans": "文件名筛选",
        "pt": "Filtro de nome",
        "ja": "ファイル名フィルター",
        "ru": "Фильтр имени",
        "ko": "파일 이름 필터",
        "it": "Filtro nome file"
    },
    "Filter by name (*.ts, node_modules, etc.)": {
        "de": "Nach Namen filtern (*.ts, node_modules, usw.)",
        "es": "Filtrar por nombre (*.ts, node_modules, etc.)",
        "fr": "Filtrer par nom (*.ts, node_modules, etc.)",
        "zh-Hans": "按名称筛选（*.ts、node_modules 等）",
        "pt": "Filtrar por nome (*.ts, node_modules, etc.)",
        "ja": "名前でフィルター（*.ts、node_modules など）",
        "ru": "Фильтр по имени (*.ts, node_modules и т.д.)",
        "ko": "이름으로 필터링 (*.ts, node_modules 등)",
        "it": "Filtra per nome (*.ts, node_modules, ecc.)"
    },
    "Hidden": {
        "de": "Ausgeblendet",
        "es": "Oculto",
        "fr": "Masqué",
        "zh-Hans": "已隐藏",
        "pt": "Oculto",
        "ja": "非表示",
        "ru": "Скрыто",
        "ko": "숨김",
        "it": "Nascosto"
    },
    "Moves the selected item to trash. Requires confirmation.": {
        "de": "Verschiebt das ausgewählte Element in den Papierkorb. Erfordert Bestätigung.",
        "es": "Mueve el elemento seleccionado a la papelera. Requiere confirmación.",
        "fr": "Déplace l'élément sélectionné vers la corbeille. Nécessite une confirmation.",
        "zh-Hans": "将所选项目移至废纸篓。需要确认。",
        "pt": "Move o item selecionado para a lixeira. Requer confirmação.",
        "ja": "選択した項目をゴミ箱に移動します。確認が必要です。",
        "ru": "Перемещает выбранный элемент в корзину. Требует подтверждения.",
        "ko": "선택한 항목을 휴지통으로 이동합니다. 확인이 필요합니다.",
        "it": "Sposta l'elemento selezionato nel cestino. Richiede conferma."
    },
    "Name:": {
        "de": "Name:",
        "es": "Nombre:",
        "fr": "Nom:",
        "zh-Hans": "名称：",
        "pt": "Nome:",
        "ja": "名前：",
        "ru": "Имя:",
        "ko": "이름:",
        "it": "Nome:"
    },
    "No file or folder selected": {
        "de": "Keine Datei oder Ordner ausgewählt",
        "es": "Ningún archivo o carpeta seleccionado",
        "fr": "Aucun fichier ou dossier sélectionné",
        "zh-Hans": "未选择文件或文件夹",
        "pt": "Nenhum arquivo ou pasta selecionado",
        "ja": "ファイルまたはフォルダーが選択されていません",
        "ru": "Файл или папка не выбраны",
        "ko": "선택된 파일 또는 폴더 없음",
        "it": "Nessun file o cartella selezionato"
    },
    "No filter": {
        "de": "Kein Filter",
        "es": "Sin filtro",
        "fr": "Aucun filtre",
        "zh-Hans": "无筛选",
        "pt": "Sem filtro",
        "ja": "フィルターなし",
        "ru": "Без фильтра",
        "ko": "필터 없음",
        "it": "Nessun filtro"
    },
    "No selection": {
        "de": "Keine Auswahl",
        "es": "Sin selección",
        "fr": "Aucune sélection",
        "zh-Hans": "未选择",
        "pt": "Nenhuma seleção",
        "ja": "選択なし",
        "ru": "Не выбрано",
        "ko": "선택 없음",
        "it": "Nessuna selezione"
    },
    "Not selected": {
        "de": "Nicht ausgewählt",
        "es": "No seleccionado",
        "fr": "Non sélectionné",
        "zh-Hans": "未选择",
        "pt": "Não selecionado",
        "ja": "未選択",
        "ru": "Не выбрано",
        "ko": "선택되지 않음",
        "it": "Non selezionato"
    },
    "Open in Application": {
        "de": "In Programm öffnen",
        "es": "Abrir en aplicación",
        "fr": "Ouvrir dans l'application",
        "zh-Hans": "在应用程序中打开",
        "pt": "Abrir no aplicativo",
        "ja": "アプリケーションで開く",
        "ru": "Открыть в приложении",
        "ko": "응용 프로그램에서 열기",
        "it": "Apri nell'applicazione"
    },
    "Opens a folder picker to select a folder to analyze": {
        "de": "Öffnet eine Ordnerauswahl, um einen zu analysierenden Ordner auszuwählen",
        "es": "Abre un selector de carpetas para seleccionar una carpeta para analizar",
        "fr": "Ouvre un sélecteur de dossier pour choisir un dossier à analyser",
        "zh-Hans": "打开文件夹选择器以选择要分析的文件夹",
        "pt": "Abre um seletor de pastas para selecionar uma pasta para analisar",
        "ja": "分析するフォルダーを選択するためのフォルダーピッカーを開きます",
        "ru": "Открывает средство выбора папки для анализа",
        "ko": "분석할 폴더를 선택하기 위한 폴더 선택기를 엽니다",
        "it": "Apre un selettore di cartelle per scegliere una cartella da analizzare"
    },
    "Opens the selected file in its default application": {
        "de": "Öffnet die ausgewählte Datei in ihrem Standardprogramm",
        "es": "Abre el archivo seleccionado en su aplicación predeterminada",
        "fr": "Ouvre le fichier sélectionné dans son application par défaut",
        "zh-Hans": "在默认应用程序中打开所选文件",
        "pt": "Abre o arquivo selecionado em seu aplicativo padrão",
        "ja": "選択したファイルをデフォルトのアプリケーションで開きます",
        "ru": "Открывает выбранный файл в приложении по умолчанию",
        "ko": "기본 응용 프로그램에서 선택한 파일을 엽니다",
        "it": "Apre il file selezionato nell'applicazione predefinita"
    },
    "Opens this folder in the treemap": {
        "de": "Öffnet diesen Ordner in der Baumkarte",
        "es": "Abre esta carpeta en el mapa de árbol",
        "fr": "Ouvre ce dossier dans la carte arborescente",
        "zh-Hans": "在树状图中打开此文件夹",
        "pt": "Abre esta pasta no mapa de árvore",
        "ja": "ツリーマップでこのフォルダーを開きます",
        "ru": "Открывает эту папку в древовидной карте",
        "ko": "트리맵에서 이 폴더를 엽니다",
        "it": "Apre questa cartella nella mappa ad albero"
    },
    "Ready to Scan": {
        "de": "Bereit zum Scannen",
        "es": "Listo para escanear",
        "fr": "Prêt à analyser",
        "zh-Hans": "准备扫描",
        "pt": "Pronto para verificar",
        "ja": "スキャン準備完了",
        "ru": "Готов к сканированию",
        "ko": "스캔 준비 완료",
        "it": "Pronto per la scansione"
    },
    "Removes the filename filter to show all files": {
        "de": "Entfernt den Dateinamenfilter, um alle Dateien anzuzeigen",
        "es": "Elimina el filtro de nombre para mostrar todos los archivos",
        "fr": "Supprime le filtre de nom pour afficher tous les fichiers",
        "zh-Hans": "删除文件名筛选以显示所有文件",
        "pt": "Remove o filtro de nome para mostrar todos os arquivos",
        "ja": "ファイル名フィルターを削除してすべてのファイルを表示",
        "ru": "Удаляет фильтр имени для отображения всех файлов",
        "ko": "파일 이름 필터를 제거하여 모든 파일 표시",
        "it": "Rimuove il filtro nome per mostrare tutti i file"
    },
    "Resets the scan state so you can select a new folder": {
        "de": "Setzt den Scanstatus zurück, damit Sie einen neuen Ordner auswählen können",
        "es": "Restablece el estado del escaneo para que pueda seleccionar una nueva carpeta",
        "fr": "Réinitialise l'état de l'analyse afin que vous puissiez sélectionner un nouveau dossier",
        "zh-Hans": "重置扫描状态，以便您可以选择新文件夹",
        "pt": "Redefine o estado de verificação para que você possa selecionar uma nova pasta",
        "ja": "スキャン状態をリセットして新しいフォルダーを選択できるようにします",
        "ru": "Сбрасывает состояние сканирования, чтобы вы могли выбрать новую папку",
        "ko": "스캔 상태를 재설정하여 새 폴더를 선택할 수 있습니다",
        "it": "Ripristina lo stato di scansione in modo da poter selezionare una nuova cartella"
    },
    "Reveals the selected item in Finder": {
        "de": "Zeigt das ausgewählte Element im Finder an",
        "es": "Revela el elemento seleccionado en Finder",
        "fr": "Révèle l'élément sélectionné dans le Finder",
        "zh-Hans": "在访达中显示所选项目",
        "pt": "Revela o item selecionado no Finder",
        "ja": "Finderで選択した項目を表示",
        "ru": "Показывает выбранный элемент в Finder",
        "ko": "Finder에서 선택한 항목 표시",
        "it": "Rivela l'elemento selezionato nel Finder"
    },
    "Scan": {
        "de": "Scannen",
        "es": "Escanear",
        "fr": "Analyser",
        "zh-Hans": "扫描",
        "pt": "Verificar",
        "ja": "スキャン",
        "ru": "Сканировать",
        "ko": "스캔",
        "it": "Scansiona"
    },
    "Scan Failed": {
        "de": "Scan fehlgeschlagen",
        "es": "Escaneo fallido",
        "fr": "Échec de l'analyse",
        "zh-Hans": "扫描失败",
        "pt": "Verificação falhou",
        "ja": "スキャン失敗",
        "ru": "Сканирование не удалось",
        "ko": "스캔 실패",
        "it": "Scansione fallita"
    },
    "Scan Folder": {
        "de": "Ordner scannen",
        "es": "Escanear carpeta",
        "fr": "Analyser le dossier",
        "zh-Hans": "扫描文件夹",
        "pt": "Verificar pasta",
        "ja": "フォルダーをスキャン",
        "ru": "Сканировать папку",
        "ko": "폴더 스캔",
        "it": "Scansiona cartella"
    },
    "Scan folder": {
        "de": "Ordner scannen",
        "es": "Escanear carpeta",
        "fr": "Analyser le dossier",
        "zh-Hans": "扫描文件夹",
        "pt": "Verificar pasta",
        "ja": "フォルダーをスキャン",
        "ru": "Сканировать папку",
        "ko": "폴더 스캔",
        "it": "Scansiona cartella"
    },
    "Scanning in progress": {
        "de": "Scan läuft",
        "es": "Escaneo en progreso",
        "fr": "Analyse en cours",
        "zh-Hans": "正在扫描",
        "pt": "Verificação em andamento",
        "ja": "スキャン中",
        "ru": "Выполняется сканирование",
        "ko": "스캔 진행 중",
        "it": "Scansione in corso"
    },
    "Scanning...": {
        "de": "Scannen...",
        "es": "Escaneando...",
        "fr": "Analyse...",
        "zh-Hans": "正在扫描...",
        "pt": "Verificando...",
        "ja": "スキャン中...",
        "ru": "Сканирование...",
        "ko": "스캔 중...",
        "it": "Scansione..."
    },
    "Select a folder to analyze": {
        "de": "Wählen Sie einen Ordner zum Analysieren aus",
        "es": "Seleccione una carpeta para analizar",
        "fr": "Sélectionnez un dossier à analyser",
        "zh-Hans": "选择要分析的文件夹",
        "pt": "Selecione uma pasta para analisar",
        "ja": "分析するフォルダーを選択",
        "ru": "Выберите папку для анализа",
        "ko": "분석할 폴더 선택",
        "it": "Seleziona una cartella da analizzare"
    },
    "Selected": {
        "de": "Ausgewählt",
        "es": "Seleccionado",
        "fr": "Sélectionné",
        "zh-Hans": "已选择",
        "pt": "Selecionado",
        "ja": "選択済み",
        "ru": "Выбрано",
        "ko": "선택됨",
        "it": "Selezionato"
    },
    "Show in Finder": {
        "de": "Im Finder anzeigen",
        "es": "Mostrar en Finder",
        "fr": "Afficher dans le Finder",
        "zh-Hans": "在访达中显示",
        "pt": "Mostrar no Finder",
        "ja": "Finderで表示",
        "ru": "Показать в Finder",
        "ko": "Finder에서 보기",
        "it": "Mostra nel Finder"
    },
    "Shown": {
        "de": "Angezeigt",
        "es": "Mostrado",
        "fr": "Affiché",
        "zh-Hans": "已显示",
        "pt": "Exibido",
        "ja": "表示中",
        "ru": "Показано",
        "ko": "표시됨",
        "it": "Mostrato"
    },
    "Size:": {
        "de": "Größe:",
        "es": "Tamaño:",
        "fr": "Taille:",
        "zh-Hans": "大小：",
        "pt": "Tamanho:",
        "ja": "サイズ：",
        "ru": "Размер:",
        "ko": "크기:",
        "it": "Dimensione:"
    },
    "Stops the current folder scan": {
        "de": "Stoppt den aktuellen Ordnerscan",
        "es": "Detiene el escaneo de carpeta actual",
        "fr": "Arrête l'analyse de dossier en cours",
        "zh-Hans": "停止当前文件夹扫描",
        "pt": "Para a verificação de pasta atual",
        "ja": "現在のフォルダースキャンを停止",
        "ru": "Останавливает текущее сканирование папки",
        "ko": "현재 폴더 스캔 중지",
        "it": "Ferma la scansione della cartella corrente"
    },
    "Try Again": {
        "de": "Erneut versuchen",
        "es": "Intentar de nuevo",
        "fr": "Réessayer",
        "zh-Hans": "重试",
        "pt": "Tentar novamente",
        "ja": "再試行",
        "ru": "Повторить попытку",
        "ko": "다시 시도",
        "it": "Riprova"
    },
    "Try scanning again": {
        "de": "Erneut scannen",
        "es": "Intentar escanear nuevamente",
        "fr": "Essayez d'analyser à nouveau",
        "zh-Hans": "重新扫描",
        "pt": "Tente verificar novamente",
        "ja": "再度スキャンしてみる",
        "ru": "Попробуйте сканирование снова",
        "ko": "다시 스캔 시도",
        "it": "Prova a scansionare di nuovo"
    },
    "Type:": {
        "de": "Typ:",
        "es": "Tipo:",
        "fr": "Type:",
        "zh-Hans": "类型：",
        "pt": "Tipo:",
        "ja": "タイプ：",
        "ru": "Тип:",
        "ko": "유형:",
        "it": "Tipo:"
    },
    "Wildcards: * (any)": {
        "de": "Platzhalter: * (beliebig)",
        "es": "Comodines: * (cualquiera)",
        "fr": "Caractères génériques: * (quelconque)",
        "zh-Hans": "通配符：*（任意）",
        "pt": "Curingas: * (qualquer)",
        "ja": "ワイルドカード：*（任意）",
        "ru": "Подстановочные знаки: * (любые)",
        "ko": "와일드카드: * (모든)",
        "it": "Caratteri jolly: * (qualsiasi)"
    }
}

def create_localization_entry(lang_code, value):
    """Create a localization entry for a language"""
    return {
        "stringUnit": {
            "state": "translated",
            "value": value
        }
    }

def create_string_entry(english_text):
    """Create a complete string entry with all translations"""
    localizations = {
        "en": create_localization_entry("en", english_text)
    }

    # Add translations for other languages
    if english_text in translations:
        for lang_code, translation in translations[english_text].items():
            localizations[lang_code] = create_localization_entry(lang_code, translation)

    return {
        "localizations": localizations
    }

# Build the complete catalog
catalog = {
    "sourceLanguage": "en",
    "strings": {},
    "version": "1.0"
}

# Add all string entries
for english_text in translations.keys():
    catalog["strings"][english_text] = create_string_entry(english_text)

# Write to file
with open("/Users/bchapuis/Projects/bchapuis/diskmanager/FolderCleaner/Localizable.xcstrings", "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)

print(f"✓ Generated translations for {len(translations)} strings in 10 languages")
print(f"  Languages: EN, DE, ES, FR, ZH-Hans, PT, JA, RU, KO, IT")
