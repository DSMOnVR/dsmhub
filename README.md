# DSMHub

The DSMHub desktop-style home page is maintained in `index.html`. The matching `index.svg` wraps that page for the jsDelivr link below.

## Links

- https://cdn.jsdelivr.net/gh/dsmonvr/dsmhub/index.svg
- https://dsmonvr.github.io/dsmhub

## Chat

Open the Launchpad and choose **Chat**. It uses Clerk username sign-in and Supabase Realtime for shared channels. The front-end contains only the Clerk publishable key and Supabase publishable key; never add Clerk secret keys or Supabase secret/service-role keys to this repository.

To enable owner tools, categories and text channels, moderator roles, message deletion, and file attachments, run `supabase-chat-upgrade.sql` once in the Supabase SQL Editor for the DSMHub project. It bootstraps the owner from the existing `undylaned` profile and creates a private 15 MB attachment bucket with signed download links. The SQL applies row-level policies so users can delete their own messages, while moderators and the owner can delete any message. Only the owner can add categories/channels or manage moderators.

The connected Clerk instance is currently the development instance, so use it for testing. Set up and connect a production Clerk instance before inviting people to the public site.

## Updates

Open Launchpad and choose **Check for updates**. The updater checks the latest `index.svg` commit and offers a commit-pinned jsDelivr link. It opens the newer version; it cannot overwrite a copy saved on someone's computer.
