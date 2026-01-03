import { useState, useEffect } from 'react'
import {
  ThemeProvider,
  createTheme,
  CssBaseline,
  Container,
  Typography,
  Box,
  Paper,
  Chip,
  CircularProgress
} from '@mui/material'
import { CheckCircle, Error } from '@mui/icons-material'

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2'
    }
  }
})

function App() {
  const [backendStatus, setBackendStatus] = useState('loading')
  const [backendData, setBackendData] = useState(null)

  useEffect(() => {
    fetch('/health')
      .then(res => {
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}`)
        }
        return res.json()
      })
      .then(data => {
        setBackendStatus('ok')
        setBackendData(data)
      })
      .catch(() => {
        setBackendStatus('error')
      })
  }, [])

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Container maxWidth="md">
        <Box sx={{ mt: 8, mb: 4 }}>
          <Typography variant="h2" component="h1" gutterBottom align="center">
            401kViz
          </Typography>
          <Typography variant="h5" color="text.secondary" align="center" paragraph>
            Plan and Optimize Your Retirement Savings
          </Typography>

          <Paper elevation={3} sx={{ p: 4, mt: 4 }}>
            <Typography variant="h6" gutterBottom>
              System Status
            </Typography>

            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 2 }}>
              <Typography>Frontend:</Typography>
              <Chip
                icon={<CheckCircle />}
                label="Ready"
                color="success"
                size="small"
              />
            </Box>

            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 2 }}>
              <Typography>Backend API:</Typography>
              {backendStatus === 'loading' && (
                <>
                  <CircularProgress size={20} />
                  <Typography variant="body2" color="text.secondary">
                    Connecting...
                  </Typography>
                </>
              )}
              {backendStatus === 'ok' && (
                <>
                  <Chip
                    icon={<CheckCircle />}
                    label="Connected"
                    color="success"
                    size="small"
                  />
                  {backendData && (
                    <Typography variant="body2" color="text.secondary">
                      Version: {backendData.version}
                    </Typography>
                  )}
                </>
              )}
              {backendStatus === 'error' && (
                <Chip
                  icon={<Error />}
                  label="Disconnected"
                  color="error"
                  size="small"
                />
              )}
            </Box>
          </Paper>

          <Box sx={{ mt: 4, textAlign: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              This is the foundation setup. Features will be implemented according to the TODO roadmap.
            </Typography>
          </Box>
        </Box>
      </Container>
    </ThemeProvider>
  )
}

export default App
