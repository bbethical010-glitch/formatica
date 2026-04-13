
$path = "packages\desktop\src\App.tsx"
$content = Get-Content -Path $path -Encoding UTF8 -Raw

# Fix 1: CompressVideoScreen Header
$oldVal1 = '                    <div className="ps">{activeTask.error}function CompressVideoScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {'
$newVal1 = @'
                <div className="info-card error" style={{ marginBottom: '24px' }}>
                  <span className="material-symbols-outlined">error</span>
                  <div className="ps">{activeTask.error}</div>
                </div>
              )}
              {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
              {activeTask.status === "processing" && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>
                    <span className="material-symbols-outlined">close</span>
                    <span>Abort Process</span>
                  </button>
                  <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function CompressVideoScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {
'@

# Fix 2: OCRScreen Header
$oldVal2 = '// ── Workflow Components ───────────────────function OCRScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {'
$newVal2 = @'
// ── Workflow Components ───────────────────────────────────────────

function OCRScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
'@

# Fix 3: Duplicate QueueScreen
$oldVal3 = 'function QueueScreen({ onBack, tasks, removeTask }: { onBack: () => void, tasks: ProcessTask[], removeTask: (id: string) => void }) {
  const activeTasks = tasks.filter((t: ProcessTask) => t.status === "processing");
  const completedTasks = tasks.filter((t: ProcessTask) => t.status === "completed" || t.status === "failed");

function QueueScreen({ onBack, tasks, removeTask }: { onBack: () => void, tasks: ProcessTask[], removeTask: (id: string) => void }) {'
$newVal3 = @'
function QueueScreen({ onBack, tasks, removeTask }: { onBack: () => void, tasks: ProcessTask[], removeTask: (id: string) => void }) {
'@

# Perform replacements
$content = $content.Replace($oldVal1, $newVal1)
$content = $content.Replace($oldVal2, $newVal2)
$content = $content.Replace($oldVal3, $newVal3)

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
