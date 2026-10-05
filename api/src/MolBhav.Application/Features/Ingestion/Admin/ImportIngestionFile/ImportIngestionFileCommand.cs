using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Ingestion.Admin.ImportIngestionFile;

/// <summary>
/// Imports an uploaded price file for a source — the fallback when the source's API is down. Produces one
/// <c>DataIngestionJob</c> (trigger <c>Upload</c>) with the usual counts and per-row errors; returns its id.
/// The caller owns <paramref name="Content"/> and disposes it after the command returns.
/// </summary>
public sealed record ImportIngestionFileCommand(
    Guid PriceSourceId,
    Guid UploadedByUserId,
    string FileName,
    long FileLength,
    Stream Content) : ICommand<CreatedResponse>;
