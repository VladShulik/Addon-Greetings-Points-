# Addon Greetings Points

Garry's Mod addon with a points system, weapon shop and admin panel.

## Features
- Earn points with popup button (`+10`) and track balance.
- Open personal points window: `points_menu`.
- Buy Half-Life 2/Garry's Mod default weapons in shop: `points_shop`.
- Admin points control panel: `points_admin` (admins only).
- Chat shortcuts:
  - `!points` — show your balance.
  - `!shop` — open weapon shop.
  - `!adminpoints` — open admin panel.

## Development check
```bash
luac -p lua/autorun/sv_points.lua
luac -p lua/autorun/cl_points.lua
```

## License
MIT, see [LICENSE](LICENSE).
